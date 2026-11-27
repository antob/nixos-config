"""Read-only diagnosis tools for hyllan, served as a stateless MCP server (JSON over HTTP POST).

Runs as the `agent` user and reuses its sudo rules (`sudo agent-logs`, `sudo syncthing-ctl`).
Every tool has fixed arguments; there is no free-form command.
"""

import json
import os
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

HOST = os.environ.get("HYLLAN_DIAG_HOST", "127.0.0.1")
PORT = int(os.environ.get("HYLLAN_DIAG_PORT", "10220"))
MAX_BYTES = 6000
MAX_LINE = 300
TIMEOUT = 20

UNIT_RE = re.compile(r"^[A-Za-z0-9:_.@-]{1,100}$")
SINCE_RE = re.compile(r"^[A-Za-z0-9 :.+-]{1,40}$")
PRIORITIES = ["emerg", "alert", "crit", "err", "warning", "notice", "info", "debug"]


def run(cmd, check=False):
    """Run a command and return its output. With check, a failing command raises, so the client sees isError."""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=TIMEOUT, stdin=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        return f"timed out after {TIMEOUT}s: {' '.join(cmd)}"
    out = (p.stdout + p.stderr).strip()
    if p.returncode != 0 and not out:
        out = f"exit status {p.returncode}"
    if check and p.returncode != 0 and "No entries" not in out:
        if "is not allowed" in out:
            out = "unit is not allowed; call log_units for the list of units whose logs can be read"
        raise ValueError(out)
    return out


def cap(text):
    """Keep the end of the output (the newest lines) within the byte budget."""
    lines = [line if len(line) <= MAX_LINE else line[:MAX_LINE] + " [cut]" for line in text.splitlines()]
    kept = []
    size = 0
    for line in reversed(lines):
        size += len(line) + 1
        if size > MAX_BYTES:
            kept.append(f"[earlier output cut at {MAX_BYTES} bytes]")
            break
        kept.append(line)
    return "\n".join(reversed(kept)) or "(no output)"


def unit_arg(args):
    unit = str(args.get("unit", ""))
    if not UNIT_RE.fullmatch(unit):
        raise ValueError("unit must be a plain unit name such as 'caddy' or 'restic-backups-hass'")
    return unit


def failed_units(_):
    return run(["systemctl", "--failed", "--no-pager", "--plain", "--no-legend"]) or "no failed units"


def unit_status(args):
    return run(["systemctl", "status", unit_arg(args), "--no-pager", "-n0"])


def log_units(_):
    return run(["sudo", "agent-logs"])


def logs(args):
    unit = unit_arg(args)
    lines = max(1, min(int(args.get("lines", 60)), 200))
    cmd = ["sudo", "agent-logs", unit, "-n", str(lines)]
    if args.get("since"):
        cmd += ["-S", check_since(str(args["since"]))]
    if args.get("grep"):
        cmd += ["-g", str(args["grep"])[:100]]
    if args.get("priority"):
        if args["priority"] not in PRIORITIES:
            raise ValueError(f"priority must be one of {', '.join(PRIORITIES)}")
        cmd += ["-p", args["priority"]]
    return run(cmd, check=True)


FAILURE_RE = "Failed with result|Scheduled restart job|code=killed|code=dumped|Out of memory|oom-kill|Failed to start"


def check_since(value):
    if not SINCE_RE.fullmatch(value):
        raise ValueError("since must look like '1 hour ago', '2026-11-27 03:00', 'yesterday' or '03:00'")
    return value


def recent_failures(args):
    since = check_since(str(args.get("since") or "1 hour ago"))
    units = run(["sudo", "agent-logs"]).split()
    out = run(
        ["sudo", "agent-logs", *units, "-S", since, "-n", "200", "-o", "with-unit", "-g", FAILURE_RE],
        check=True,
    )
    if "No entries" in out:
        return f"No failures, kills or restarts logged since {since} for any of the {len(units)} readable units."
    return out


def timers(_):
    return run(["systemctl", "list-timers", "--all", "--no-pager"])


def zpool_status(_):
    return run(["zpool", "status"])


def disk_usage(_):
    return run(["df", "-h", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "overlay"])


def deployed_generation(_):
    return run(["readlink", "-f", "/run/current-system"])


def backup_status(_):
    # Idle services are not loaded, so a glob on .service matches nothing; the timers are always loaded.
    timers = run(["systemctl", "list-units", "restic-backups-*.timer", "--all", "--plain", "--no-legend"])
    services = [line.split()[0].removesuffix(".timer") + ".service" for line in timers.splitlines() if line.strip()]
    if not services:
        return "no restic backup timers found"
    out = run(
        ["systemctl", "show", *services, "--no-pager"]
        + [f"-p{p}" for p in ("Id", "ActiveState", "Result", "ExecMainStatus", "ExecMainExitTimestamp")]
    )
    rows = []
    for block in out.split("\n\n"):
        kv = dict(line.split("=", 1) for line in block.splitlines() if "=" in line)
        if kv.get("Id"):
            rows.append(
                f"{kv['Id']}: {kv.get('ActiveState', '?')}, result={kv.get('Result', '?')}, "
                f"exit={kv.get('ExecMainStatus', '?')}, last exit {kv.get('ExecMainExitTimestamp') or 'never'}"
            )
    return "\n".join(rows) or out


def syncthing_status(_):
    return run(["sudo", "syncthing-ctl", "status"])


UNIT_PROP = {"unit": {"type": "string", "description": "Unit name, with or without .service"}}


def tool(name, description, func, properties=None, required=None):
    return {
        "name": name,
        "description": description,
        "func": func,
        "schema": {"type": "object", "properties": properties or {}, "required": required or []},
    }


TOOLS = [
    tool("failed_units", "List failed systemd units on the home server hyllan (not Home Assistant devices). Start here for any question about whether hyllan is healthy.", failed_units),
    tool("unit_status", "Show systemctl status of one unit (state, since, main PID, exit code).", unit_status, UNIT_PROP, ["unit"]),
    tool("log_units", "List the units whose journal can be read with the logs tool.", log_units),
    tool(
        "logs",
        "Read the newest journal lines of one allowed unit. Output is capped; narrow with since, grep or priority.",
        logs,
        {
            **UNIT_PROP,
            "lines": {"type": "integer", "description": "Number of lines, 1 to 200 (default 60)"},
            "since": {"type": "string", "description": "e.g. '1 hour ago', 'yesterday', '2026-11-27 03:00' (not 'today 01:00')"},
            "grep": {"type": "string", "description": "Regex filter on the message"},
            "priority": {"type": "string", "enum": PRIORITIES, "description": "Show this priority and worse"},
        },
        ["unit"],
    ),
    tool(
        "recent_failures",
        "Find crashes, kills, failed starts and restarts logged by ANY readable unit since a point in time, in one call, "
        "newest last. Use this first for 'did anything crash or fail recently' instead of reading units one by one.",
        recent_failures,
        {"since": {"type": "string", "description": "Default '1 hour ago'. e.g. '10 minutes ago', 'yesterday', '03:00'"}},
    ),
    tool("timers", "List systemd timers with last and next run.", timers),
    tool("zpool_status", "Show ZFS pool health, errors and scrub state.", zpool_status),
    tool("disk_usage", "Show disk usage of the mounted filesystems.", disk_usage),
    tool("deployed_generation", "Show the store path of the running NixOS generation.", deployed_generation),
    tool("backup_status", "Show whether the nightly restic backups of hyllan succeeded: state, result and last run of each backup unit.", backup_status),
    tool("syncthing_status", "Show Syncthing connections, folder state and errors.", syncthing_status),
]
BY_NAME = {t["name"]: t for t in TOOLS}


def call_tool(params):
    t = BY_NAME.get(params.get("name"))
    if t is None:
        return {"content": [{"type": "text", "text": f"unknown tool {params.get('name')!r}"}], "isError": True}
    try:
        text, error = cap(t["func"](params.get("arguments") or {})), False
    except (ValueError, TypeError) as e:
        text, error = str(e), True
    return {"content": [{"type": "text", "text": text}], "isError": error}


def handle(msg):
    method = msg.get("method")
    if method == "initialize":
        return {
            "protocolVersion": (msg.get("params") or {}).get("protocolVersion", "2024-11-05"),
            "capabilities": {"tools": {}},
            "serverInfo": {"name": "hyllan-diag", "version": "1"},
        }
    if method == "ping":
        return {}
    if method == "tools/list":
        return {"tools": [{k: t[k] for k in ("name", "description")} | {"inputSchema": t["schema"]} for t in TOOLS]}
    if method == "tools/call":
        return call_tool(msg.get("params") or {})
    raise KeyError(method)


class Handler(BaseHTTPRequestHandler):
    def send(self, code, body=None):
        data = json.dumps(body).encode() if body is not None else b""
        self.send_response(code)
        if data:
            self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        if self.path != "/mcp":
            return self.send(404)
        try:
            msg = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))))
            if not isinstance(msg, dict):
                raise ValueError
        except ValueError:
            return self.send(400, {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": "parse error"}})
        if "id" not in msg:
            return self.send(202)
        try:
            body = {"jsonrpc": "2.0", "id": msg["id"], "result": handle(msg)}
        except KeyError as e:
            body = {"jsonrpc": "2.0", "id": msg["id"], "error": {"code": -32601, "message": f"method not found: {e}"}}
        self.send(200, body)

    def do_GET(self):
        self.send(405)

    def log_message(self, fmt, *args):
        print(self.address_string(), fmt % args, flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
