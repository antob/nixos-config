"""OpenAI-style text-to-speech endpoint in front of a Wyoming Piper server.

POST /v1/audio/speech {"input": ..., "voice": ..., "response_format": "opus"|"mp3"|"wav"}
returns the audio. Listens on localhost only and ignores the bearer token.
"""

import argparse
import asyncio
import json
import logging
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from wyoming.audio import AudioChunk, AudioStart, AudioStop
from wyoming.client import AsyncTcpClient
from wyoming.tts import Synthesize, SynthesizeVoice

FORMATS = {
    "opus": (["-c:a", "libopus", "-b:a", "32k", "-f", "ogg"], "audio/ogg"),
    "mp3": (["-c:a", "libmp3lame", "-b:a", "64k", "-f", "mp3"], "audio/mpeg"),
    "wav": (["-f", "wav"], "audio/wav"),
}

_LOGGER = logging.getLogger("tts-bridge")


def clean(text: str) -> str:
    # Markdown markers would otherwise be read out.
    text = re.sub(r"[*_`#]+", "", text)
    text = re.sub(r"^\s*[-•]\s+", "", text, flags=re.MULTILINE)
    return re.sub(r"\s+", " ", text).strip()


async def synthesize(host: str, port: int, text: str, voice: str) -> tuple[bytes, int, int, int]:
    pcm = bytearray()
    rate, width, channels = 22050, 2, 1
    async with AsyncTcpClient(host, port) as client:
        await client.write_event(Synthesize(text=text, voice=SynthesizeVoice(name=voice)).event())
        while (event := await client.read_event()) is not None:
            if AudioStart.is_type(event.type):
                start = AudioStart.from_event(event)
                rate, width, channels = start.rate, start.width, start.channels
            elif AudioChunk.is_type(event.type):
                pcm += AudioChunk.from_event(event).audio
            elif AudioStop.is_type(event.type):
                break
    return bytes(pcm), rate, width, channels


def encode(pcm: bytes, rate: int, width: int, channels: int, fmt: str) -> bytes:
    sample_fmt = {1: "u8", 2: "s16le", 4: "s32le"}[width]
    args, _ = FORMATS[fmt]
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", sample_fmt,
           "-ar", str(rate), "-ac", str(channels), "-i", "-", *args, "-"]
    return subprocess.run(cmd, input=pcm, capture_output=True, check=True).stdout


def make_handler(args: argparse.Namespace):
    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            if self.path.rstrip("/") != "/v1/audio/speech":
                self.send_error(404)
                return
            try:
                body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
                text = clean(str(body.get("input", "")))
                fmt = body.get("response_format") or "opus"
                if not text or fmt not in FORMATS:
                    self.send_error(400, "empty input or unsupported response_format")
                    return
                voice = body.get("voice") or args.voice
                audio = encode(*asyncio.run(synthesize(args.piper_host, args.piper_port, text, voice)), fmt)
            except Exception as err:  # noqa: BLE001
                _LOGGER.exception("synthesis failed")
                self.send_error(502, str(err))
                return
            self.send_response(200)
            self.send_header("Content-Type", FORMATS[fmt][1])
            self.send_header("Content-Length", str(len(audio)))
            self.end_headers()
            self.wfile.write(audio)

        def log_message(self, format: str, *log_args) -> None:
            _LOGGER.info("%s %s", self.address_string(), format % log_args)

    return Handler


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=10210)
    parser.add_argument("--piper-host", default="127.0.0.1")
    parser.add_argument("--piper-port", type=int, default=10200)
    parser.add_argument("--voice", default="en_GB-jenny_dioco-medium")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(args)).serve_forever()


if __name__ == "__main__":
    main()
