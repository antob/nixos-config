# ZeroClaw personal assistant on hyllan

Status (2026-11-22): Phases 1 and 2 done, Phase 3 working. Sources: ZeroClaw docs, schema and `nix/module.nix` at tag `v0.9.0`; OpenRouter models API; HA `mcp_server` and `llm` docs.

## Handoff state (2026-11-22)

Running and verified by the user: Telegram bot `@antob_home_bot` -> ZeroClaw 0.9.0 on hyllan -> llama-server (preset `zeroclaw`, Qwen3.6-35B-A3B) on desktob over wg0. Language rule (Swedish default, English when addressed in English), reminders (`cron_add`), long-term memory, HA lights by device, area and floor all work. Both hosts were switched after the sampler/cap change and the `SOUL.md` "Home" section.

Done and switched (2026-11-22): `auto_approve` for GetLiveContext, GetDateTime, HassTurnOn, HassTurnOff (volume still asks); `excluded_tools` for 6 unused HA tools (15 HA tools left); custom chat template on desktob that fixes reply language and emojis (see "Reply language investigation"). Verified in Telegram after `/new`: Swedish, Swedish, English, Swedish commands each answered in the right language, no emojis, lights switched.

Done earlier: `risk_profiles.assistant.auto_approve` (GetLiveContext, GetDateTime, HassTurnOn, HassTurnOff) in `modules/hosts/hyllan/zeroclaw.nix`. Reason: the Telegram "Always" button does not persist, so every call asked for approval. Checked 2026-11-22: `nix eval` shows the four names; the running unit (started 16:07, config `4522hzmw...-zeroclaw-assistant-config.toml`) has no `auto_approve`, so hyllan is not switched yet. The HA tool names are not in the trace or the journal (MCP tools are deferred), so step 2 needs a fresh `tools/list` from HA.

Nothing is committed. Changed or new files: `flake.nix`, `flake.lock` (only the `zeroclaw` input), `modules/ai/llama-cpp.nix`, `modules/ai/_files/zeroclaw-qwen3.6.jinja` (new, `git add -N`), `modules/hosts/desktob/default.nix`, `modules/hosts/hyllan/{backup.nix,secrets.yaml,zeroclaw.nix}`, `modules/hosts/hyllan/_files/zeroclaw/{IDENTITY.md,SOUL.md}`, `modules/hosts/desktob/secrets.yaml` (check `git status`), and this doc (untracked). Commit only when the user asks.

Done 2026-11-22, not yet switched: debug settings removed from `zeroclaw.nix` (`RUST_LOG`, `observability.log_llm_request_payload`); hyllan needs a switch. Local test data in `/tmp` deleted. The trace on hyllan still holds full prompts until its 200-event window rolls over.

Done 2026-11-22 in HA (entity registry, backup in `/tmp/registries-2026-11-22`): Swedish aliases (indefinite and definite form) on all 12 exposed lights, e.g. Taklampa/Taklampan, TV-lampa/TV-lampan, Julgran/Julgranen, Fönsterlampa, Fönsterbelysning, Entrélampa, Ljusslinga, Altanlampa, Kvällsbelysning, Utebelysning. Note: the earlier "taklampan" failure was HA's "No entities matched the device class" with name `ceiling light`, so aliases may not be the whole fix. Seen while listing: `switch.upstairs_closet_hyllan` (the plug that powers hyllan) is exposed to Assist; it was disabled so not a tool. Un-exposed on 2026-11-22 at the user's request; it no longer appears in the exposed-entities list.

Music (2026-11-22, investigation): Music Assistant runs as `podman-mass` (`modules/hosts/hyllan/music-assistant.nix`, image `server:beta`). HA has the `music_assistant` integration loaded; its players are `media_player.{living_room,kitchen,upstairs_hall}_speaker` and the group `media_player.all_speakers`, and it offers `music_assistant.play_media` (with `radio_mode`), `search`, `get_library`, `get_queue`, `play_announcement`, `transfer_queue`. Options: (1) test HA's existing `media_player__search_media`/`play_media` tools as they are; (2) an HA script `play_music(query, media_type, player, radio_mode)` exposed to Assist that calls `music_assistant.play_media`; (3) a community Music Assistant MCP server connected directly to ZeroClaw (third-party, more tools, bypasses HA's exposure). Recommended: 1, then 2 if 1 is unreliable.

First Telegram test of option 1: pause/unpause worked (on the Sonos entity), search found nothing. Cause: both the Sonos integration players and the MA "Speaker" players were exposed, so rooms were ambiguous and the bot searched the Sonos entity. Un-exposed `media_player.{living_room_sonos_play_5,kitchen_sonos_one,upstairs_hall_sonos_move,living_room_apple_tv_airplay}`; exposed media players are now the three MA speakers, `all_speakers` and `living_room_apple_tv`. `media_player.search_media` on `media_player.living_room_speaker` for "Depeche Mode" returns the MA library artist (`library://artist/65`) first, then Bandcamp and SoundCloud. `search_media`, `HassMediaPause` and `HassMediaUnpause` were "Always" approved in Telegram (not persisted across restarts).

Second Telegram test ("Spela Depeche mode i vardagsrummet"): the bot called `search_media` then `play_media` with the library artist. MA started "Fetching tracks to play for artist Depeche Mode (selection: all_tracks, order: shuffled_tracks)", Spotify's part timed out, and MA gave up after 120 s; the HA MCP call was cut at about 60 s, so the bot sent no reply (HA logged "transport write blocked"). Retries then waited on MA's playback lock. Direct `music_assistant.play_media` on `media_player.kitchen_speaker`, time to playing: artist with `radio_mode: true` 10.2 s, track ("Enjoy the Silence", artist set) 2.6 s, album ("Violator") 2.1 s. So option 2 (a script calling `music_assistant.play_media` with a name, type and optional radio mode) avoids the slow all-tracks path.

Implemented option 2 (2026-11-22): HA script `script.play_music` (created through the config API, exposed to Assist, committed in the HA config repo), MCP tool `ha__script__play_music`. Fields: `query`, `media_type` (artist/album/track/playlist), optional `artist`, `player` (living_room/kitchen/upstairs_hall/all, mapped to the MA speakers and `all_speakers`), `source` (any/spotify/youtube_music), `radio_mode`. `source: any` calls `music_assistant.play_media` by name. For spotify/youtube_music it calls `music_assistant.search` (MA config entry `01M7JPREXTXNNSD48CJJ45019B`), takes the first result whose URI starts with `spotify`/`ytmusic`, whose name contains the query and whose artists contain `artist` if given, and plays that URI; with no match it stops and returns response data `{"error": "Nothing found on <source> for '<query>' ... Nothing is playing."}` (Spotify search always returns loosely related results, so the name check is required). A `stop` with `error: true` was tried first: HA reported the call as successful and `stop` messages are not templated, so the bot would not have seen it. Verified through `/api/mcp/assist` `tools/call`: the bot receives the message with `isError: false`. User tested the switched setup in Telegram: works.

Added to `auto_approve` (edited, not switched): `HassMediaPause`, `HassMediaUnpause`, `HassSetVolume`, `HassSetVolumeRelative`, `HassMediaPlayerMute`, `HassMediaPlayerUnmute`. Then also `HassMediaNext`, `HassMediaPrevious`, `light__HassLightSet`, so all 14 remaining HA tools are auto-approved; a tool HA adds later still asks. Tested on the kitchen speaker: album 2.4 s, Spotify track 2.7 s, any-source track 2.3 s, nonsense Spotify query plays nothing. `zeroclaw.nix` (edited, not switched): `ha__script__play_music` in `auto_approve`, `ha__media_player__search_media` and `ha__media_player__play_media` in `excluded_tools`.

Phase 4 findings (2026-11-22, ZeroClaw v0.9.0 source): Telegram voice transcription needs `transcription.enabled = true`, a provider `providers.transcription.local_whisper.<alias> = { uri; timeout_secs; max_audio_bytes; }` and `agents.assistant.transcription_provider = "local_whisper.<alias>"` (`resolved_transcription_manager` in `orchestrator/mod.rs`). `transcription.max_duration_secs` caps memo length. The local_whisper provider posts only a multipart `file` part (Telegram voice is `.ogg`, sent as `audio/ogg`) and reads `{"text": ...}`; the `language` config field is not sent, so the language must be set on the server (`-l auto`). whisper.cpp `whisper-server` (nixpkgs `whisper-cpp` 1.9.5) needs `--convert` and ffmpeg on PATH to accept OGG. It has no authentication. Hosts: hyllan is a Ryzen 5 5600G (6 cores, 12 threads, about 13 GB RAM free); desktob is a Ryzen AI Max+ 395 with a Radeon 8060S and already runs whisper `large-v3-turbo` on Vulkan for voxtype. Decided: desktob.

Implemented (not built or switched): new aspect `whisper-server` (`modules/ai/whisper-server.nix`, `git add -N`): systemd unit with the llama-cpp sandbox, model `ggml-large-v3-turbo.bin` pinned to Hugging Face commit `5359861c` (sha256 from the LFS etag, 1.6 GB), `--language auto --convert --tmp-dir /tmp --flash-attn`, option `allowedClients` (per interface) rendered as an nftables `extraInputRules` accept rule. desktob: `pkgs.whisper-cpp-vulkan`, `0.0.0.0:8091`, `allowedClients.wg0 = [ "10.64.1.2" ]` (wg0 is not a trusted interface on desktob, so only hyllan reaches it). hyllan `zeroclaw.nix`: `transcription.enabled`, provider `local_whisper.desktob` (`http://10.64.1.6:8091/inference`, 60 s timeout), agent `transcription_provider`. Default memo cap is 120 s (`transcription.max_duration_secs`).

desktob switched 2026-11-22: `whisper-server` active, model loaded on the GPU (`use gpu = 1`, `flash attn = 1`). The ggml backends load from nixpkgs' shared `llama-cpp-0.9.0` libs (ROCm, Vulkan, CPU), and device 0 is ROCm (`ROCm0 total size = 1623.92 MB`), not Vulkan. The Mesa shader-cache warning (`//.cache` read-only) only matters for Vulkan. Firewall: hyllan gets HTTP 200 on `10.64.1.6:8091`; hyllan via desktob's LAN address `192.168.1.143:8091` times out; nft rule `iifname "wg0" ip saddr 10.64.1.2 tcp dport 8091 accept`.

hyllan switched 2026-11-22: Telegram voice notes work in Swedish and English (user verified). whisper-server log: 2.4 to 3.3 s clips, language auto-detected (sv p=0.93 and 0.99, en p=0.99), each transcribed within about a second.

Phase 4b plan (2026-11-22): HA has only Google Translate TTS (cloud, not used) and no Wyoming integration. HA `internal_url` is `https://ha.antob.net`, language `en`.
1. Piper on hyllan: `modules/hosts/hyllan/piper.nix` (`git add -N`), nixpkgs `services.wyoming.piper.servers.home`, wyoming-piper 2.5.2, default voice `sv_SE-nst-medium`, `tcp://127.0.0.1:10200`, zeroconf off, unit `wyoming-piper-home` readable via agent-logs. Voices download to `/var/lib/wyoming/piper` on first use (not backed up, re-downloadable). Written, not switched.
2. HA: add the Wyoming integration (127.0.0.1:10200), check the voice list (one server should serve `en_US-lessac-medium` too; otherwise a second server), create `script.announce(message, player, language)` calling `tts.speak` on the MA speaker (MA handles it as an announcement and resumes music), expose it, test on the kitchen speaker.
3. ZeroClaw: `ha__script__announce` in `auto_approve`; reminders can then be spoken (`cron_add` agent job).

Status 2026-11-22: step 1 switched (`wyoming-piper-home` active on 127.0.0.1:10200, Swedish voice downloaded). Step 2 done: Wyoming integration added (entry `piper`, entity `tts.piper`); one server offers all voices and downloads each on first use (Swedish: nst, alma, lisa). `script.announce(message, player, language)` calls `tts.speak` with `sv_SE-nst-medium` or `en_US-lessac-medium`, exposed as MCP tool `ha__script__announce`, committed in the HA config repo. MA plays it as an announcement with a pre-announce chime, fetching `https://ha.antob.net/api/tts_proxy/...mp3`. The script returns when playback is done (about 8 s for a short Swedish sentence, 12 s for English including the first voice download). The kitchen test interrupted music that was playing there (it resumed). Use the living room speaker for tests from now on (user request). Step 3: `ha__script__announce` added to `auto_approve` (edited, not switched). Voices changed at the user's request: `sv_SE-alma-medium` and `en_GB-jenny_dioco-medium` (language `en_GB`); tested on the living room speaker (MA player name "Office"), about 13 s per call including the first voice download.

Volume and chime (user request: volume 25, own soft chime): HA's `music_assistant` media player passes `extra.use_pre_announce`, `extra.pre_announce_url` and `extra.announce_volume` from `media_player.play_media` with `announce: true` to MA (`media_player.py` `async_play_media`), and resolves `media-source://tts/tts.piper?message=...&language=...&voice=...` itself. Chime: synthesised locally with ffmpeg (two sine tones, 880 Hz then 1318.5 Hz 160 ms later, exponential decay, 1.3 s, peak -7 dB, sha256 `ff9c8a22...`), copied to `/mnt/tank/services/hass/home-assistant/www/announce-chime.mp3` (root-owned dir, needed `ssh hyllan.lan`), served at `https://ha.antob.net/local/announce-chime.mp3`. Not in the HA config git allow-list. Played alone on the living room speaker at volume 25; the user kept it. `script.announce` now calls `media_player.play_media` (`announce: true`, `media-source://tts/tts.piper?message={{ message | urlencode }}&language=...&voice=...`, `extra: { use_pre_announce: true, pre_announce_url: <chime>, announce_volume: 15 }`, lowered from 25 and then 20 at the user's request); tested on the living room speaker (7.7 s for a Swedish sentence including chime), committed in the HA config repo.

hyllan switched 2026-11-22 with `ha__script__announce` auto-approved; announcements from Telegram verified by the user. Phase 4b done.

Phase 5 options (2026-11-22, not decided): ZeroClaw 0.9.0's gateway has no OpenAI-compatible endpoint (routes: `/webhook` for paired clients, `/api/*`, `/ws/chat`), and the `webhook` channel is fire-and-forget with an HMAC secret. Conversation agent choices for the HA Assist pipeline: (a) HA local intents only (offline, fast, fixed sentence patterns, one language per pipeline); (b) local intents first, fallback to an LLM through HA's built-in Ollama integration (ollama already runs on desktob on wg0), a separate brain without ZeroClaw's memory and reminders; (c) ZeroClaw via the community `ha-zeroclaw-conversation` component (same brain, unvetted code inside HA). STT: `wyoming-faster-whisper` on hyllan (CPU, keeps lights working when desktob is off) or on desktob (faster CPU; CTranslate2 has no ROCm in nixpkgs). Satellite hardware unknown: HA Companion app (push to talk) or an ESPHome voice device (on-device wake word).

Decided (user): HA Companion app on the iPhone (push to talk, no wake word), and option (c), ZeroClaw as the Assist conversation agent.

Component review (2026-11-22): `LorenzoVasi/ha-zeroclaw-conversation`, single author, 32 commits, `v0.3.0` = HEAD (no later commits), about 3,500 lines of Python, no requirements, listed in HA's Marketplace (repository id `1348794742`). Talks only to the ZeroClaw gateway: `/ws/chat` (one session per HA conversation id, streaming, tool approvals sent as phone notifications), `/health`, `/api/quickstart/state` (agent list), `/api/sessions` (deletes only sessions it opened, after 24 h idle). Config-changing calls (`/api/quickstart/apply`, `/api/personality/<file>`, `/api/config/prop` to grant an MCP bundle) run only in the "create a new agent" setup path; choosing the existing `assistant` agent avoids them. Optional inbound HA webhook (`local_only`, id is the secret) for agent notifications and watches; not needed. No subprocess, eval or other outbound hosts. Setup asks for host, API token (gateway bearer token from pairing), optional webhook secret and HA URL. The pairing token gives full gateway API access, so it must stay in HA only.

Phase 5 plan: (1) Wyoming STT: `wyoming-faster-whisper` (nixpkgs 3.8.1), proposed on desktob CPU behind the same wg0 rule as whisper-server, model downloaded to a persisted data dir; one pipeline per language (Svenska, English) since the STT language is fixed per pipeline. (2) Install the component from the Marketplace at `v0.3.0` and restart HA (user's yes needed). (3) Pair: read the one-time pairing code from the ZeroClaw journal, `POST /pair` on 127.0.0.1:42617 from hyllan, pass the token into the config flow without printing it, choose agent `assistant`. (4) Assist pipelines: ZeroClaw agent, faster-whisper STT, Piper TTS (alma / jenny_dioco). (5) Select the pipeline in the Companion app and test.

User decisions: STT on desktob; HA restart approved; Swedish recognition is required, Swedish speech output matters less (but Swedish replies need a Swedish voice), so one Swedish pipeline (English optional). If Swedish recognition is weak, try KBLab `kb-whisper`.

Step 2: the Marketplace API install was refused (`warning_not_accepted`, the agent account has not accepted the third-party warning); the user installed `v0.3.0` in the UI and HA restarted. Installed files hash-identical to the reviewed tag; no Plejd `*_pressed` events after the restart. Step 3 changed: ZeroClaw writes paired tokens into `config.toml` as SHA-256 hashes (`pairing.rs`, `persist_pairing_tokens`), and the module re-renders that file on every start, so a runtime pairing would be lost. Instead a random token was generated locally (kept in `/tmp/zc-ha/token`, mode 0600, until it is entered in HA, then deleted) and its hash declared in `zeroclaw.nix` as `gateway.paired_tokens` (pre-hashed values are accepted, `is_token_hash`). With a token configured, the startup pairing code is no longer printed.

Both hosts switched 2026-11-22. desktob: `wyoming-faster-whisper-assist` ready after downloading `dropbox-dash/faster-whisper-large-v3-turbo` (about 2.5 min, into the persisted dir), port 10300 reachable from hyllan. HA: Wyoming integration `faster-whisper` (10.64.1.6:10300, entity `stt.faster_whisper`). Gateway token: `/api/status` 200 with it, 401 without. ZeroClaw Conversation set up through the config flow API (host `http://127.0.0.1:42617`, agent `assistant`, no webhook secret, no HA URL so the notify/watch webhook is off): entities `conversation.zeroclaw_assistant_zeroclaw_assistant` and `ai_task.zeroclaw_assistant_zeroclaw_assistant`. Pipeline "ZeroClaw (svenska)" (id `01m82f59pwvxypmxtje85vef5s`): language sv, ZeroClaw agent, `stt.faster_whisper` sv, `tts.piper` `sv_SE-alma-medium`, `prefer_local_intents: false`. Set as HA's preferred pipeline (the iOS Companion app's Assist settings have no pipeline choice; it uses the preferred one). Token file deleted. Text test through the agent (`conversation/process`, "Vad är klockan?", sv): correct time in Swedish in 8.2 s, but the reply was "Härligt att se dig! Låt mig kolla klockan åt dig.Det är 21:30 på söndag kväll. 🕘": a greeting (the component prepends an English "greet the speaker by name" note on a conversation's first turn, `_SPEAKER_CONTEXT_TEMPLATE` in `conversation.py`), pre-tool narration streamed and glued to the answer, and an emoji. The English note may also affect the template's language check for messages without Swedish markers, since `/ws/chat` messages may lack the `[... :00] ` timestamp the check splits on.

First Companion app tests (2026-11-22): the iOS app's Assist settings have no pipeline picker, so the pipeline was set as preferred. Early attempts produced Whisper silence hallucinations ("Textning.nu", "Tack så mycket.", "Textning Stina Hedin www.btistudios.com"): HA's VAD saw little or no speech. A browser test on desktob was invalid (its only input is the unconnected onboard analog input). Server side verified with clean Piper speech: HA STT API and the full pipeline (`assist_pipeline/run` from stt, with HA's audio processing and VAD) both returned " Tänd tacklampan i vardagsrummet.". Later phone attempts worked ("Tänd taklampan i vardagsrummet" recognised and performed), after some nonsense first. Open: STT latency on desktob's CPU (about 6 s for 2 to 8 s of audio, `turbo`, beam 5); Swedish TTS (alma) sounds poor to the user.

Speed and hallucination changes (2026-11-22): desktob `faster-whisper.nix` now passes `--beam-size 1 --compute-type int8 --cpu-threads 8 --vad-filter` (Silero VAD inside faster-whisper; written, not switched). The tool also supports biasing toward HA entity, area and floor names (`--hass-token`, `hass` extra), not used yet. Pipeline `prefer_local_intents` set to true (live): "Vad är klockan?" answered by HA locally in 0.07 s ("21:56"). Locally handled commands do not reach ZeroClaw. Test scripts for the pipeline (`/tmp/stt-test-scripts/pipe.py`, `intent.py`) and the clean clip (`/tmp/stt-test/tts.raw`) are temporary.

desktob switched: clean clip still " Tänd tacklampan i vardagsrummet.", 3.1 s from HA's speech-end to text (was 6.1 s); 3 s of digital silence and 3 s of low noise now return `stt-no-text-recognized` instead of subtitle credits. User verified on the phone: works, speed acceptable. Phase 5 done. Temporary test files deleted; `/tmp/review-hazc` (component clone) kept until the user decides on component changes. Step 1 written (not switched): `modules/hosts/desktob/faster-whisper.nix` (`git add -N`), server `assist`, `--stt-library faster-whisper --model turbo --language sv`, `tcp://0.0.0.0:10300`, zeroconf off, nft rule for 10.64.1.2 on wg0, `/var/lib/private/wyoming/faster-whisper` persisted.

Next steps, in order:
1. Phase 3b music (`media_player__search_media`/`play_media` already exposed by HA), then Phase 4 voice memos and announcements, Phase 6 vault (Syncthing receive-only `Work`, stdio MCP parser). Blocked on the user: one sanitized daily note with the hours table and its filename.

Working notes for whoever continues: the user builds and switches hosts themselves (`just build hyllan`, `just deploy switch hyllan`, same for desktob); give the commands and stop. Verify with `nix eval` only. `ssh hyllan.lan` needs a YubiKey touch (tell the user first, set a timeout); `ssh agent@hyllan.antob.net` needs none and can run `sudo agent-logs zeroclaw-assistant`. The ZeroClaw trace is `/mnt/tank/services/zeroclaw/data/state/runtime-trace.jsonl` (root-only, 200-event rolling). llama-server needs the API key (`/run/secrets/llama_api_key`, root-only): the user runs key-dependent tests. Style: short answers, no em dashes, no emojis, one small change per round.

## Reply language investigation (2026-11-22)

Switched 2026-11-22: `auto_approve` works (light prompts no longer ask). Edited but NOT built or switched yet: `excluded_tools` for 6 unused HA tools (HassBroadcast, HassCancelAllTimers, the 4 `todo__*`), leaving 15 HA tools.

Switched 2026-11-22: `excluded_tools` live. Telegram test after `/new`: area on/off and single lamp worked without approval, volume asked (and "Always" was pressed). Bug: the first two Swedish area commands were answered in English. HA tool results are English JSON (`speech: {}`, English entity and area names) plus an injected `[Memory context]`, which likely pulls the reply to English. Edited, not switched: a `SOUL.md` language line saying tool results, device names and memory notes never decide the language. Emojis still appear despite the style rule.

Result after switching the `SOUL.md` line: worse, 5/5 Swedish commands answered in English (no emojis this time). The line is in the system prompt (trace copied to `/tmp/zc-trace3.jsonl`). What the model sees: about 12k chars of English ZeroClaw system prompt with `SOUL.md` in the middle, the user turn wrapped in English `[turn-context]` text, then an English HA JSON result last. Candidates: the `presence-penalty = 1.5` sampler (Qwen notes it may cause language mixing; added at the same switch as the earlier fix), and the lack of a Swedish example. Replay test `/tmp/langtest2/run.py` (variants base, presence 0, bilingual example line, both; Swedish first turn, Swedish third turn, English control) is ready for the user to run on desktob. Replay results (5 runs each): Swedish first turn was Swedish in every variant (5/5), although live it was English. Third turn was English in every variant (0/5 Swedish): the earlier English replies in history get copied, and no prompt or sampler tweak overrides that. English control: base 2/5 English, every other variant 0/5 (the example line forces "Klart, ..." even for English). Presence penalty made no clear difference. The replay sent no tools, while live requests carry 21 tool schemas (`tools_count: 21`, which the Qwen template appends after the system prompt, so after `SOUL.md`). Replay with the 15 real HA tool schemas (`/tmp/ha-tools.json`) reproduces it: Swedish first turn English 4/5 (presence 0: 5/5), English control mostly English. So the tool block, which the Qwen template renders after the system text, overrides `SOUL.md`. Candidate fix on the llama-server side: a custom `chat-template-file` in the `zeroclaw` preset that adds a language reminder. Correction: the rendered prompt starts with `# Tools`, so this template already puts tools before the system text and `SOUL.md`; reordering is moot. Variants now: reminder at the end of the system block (M), and a short system turn right before the assistant reply (G).

Result (5 runs each, with tools): base sv-first 1/5 Swedish, en-first 5/5 English. M ("Reply in the language of the user's latest message: Swedish if it is Swedish, English if it is English." appended at the end of the system block) sv-first 5/5 Swedish, en-first 5/5 English, sv-third still English (history already English). G answers Swedish to everything (overcorrects). Prompt layout: tools end at char 8916, `SOUL.md` at 11648, system block ends at 21708: about 10k chars of ZeroClaw text follow `SOUL.md` (skills, runtime, a 7k list of deferred built-in tools, and a built-in Telegram block that says "Use emoji naturally to add personality", which explains the emojis). ZeroClaw 0.9.0 has no option to append text to the system prompt (checked `schema.rs`). Proposed fix: a custom chat template for the `zeroclaw` preset that appends the M line (and possibly a no-emoji line) at the end of the system block. Needs the original template from `/props?model=zeroclaw`.

Implemented (not built or switched): `modules/ai/_files/zeroclaw-qwen3.6.jinja` is the model's template (from `/props`, Unsloth version) with one block added before the tools section that appends "Reply in the language of the user's latest message: Swedish if it is Swedish, English if it is English. No emojis." to the system text. The `zeroclaw` preset sets `chat-template-file` to it (checked with `nix eval` on the preset text). New file added with `git add -N`. The "No emojis." part was not in the tested M line. Re-check if the model or its GGUF template changes. Verify after switching desktob: `/apply-template` output ends the system block with the line, then a Telegram test after `/new`.

Switched desktob 2026-11-22. Telegram after `/new`: three Swedish commands answered in Swedish, no emojis. An English command after them ("Turn off all lights in the Livingroom") was answered in Swedish: the history effect seen in the replay's third-turn case, now in the other direction. Not yet tested in the replay: English after Swedish history. Test `/tmp/langtest2/run3.py` compares the current line (L0) with two stronger wordings (L1 "even if earlier replies ... used another language", L2 "look only at the user's latest message ... earlier messages and replies do not count") on first turns and on English-after-Swedish and Swedish-after-English history.

Result: no wording overrides history. Swedish-after-English history 0/5 for all three; English-after-Swedish L0 3/5, L1 0/5, L2 4/5 (L2 also lost a Swedish first turn and brought emojis back). Next idea: the template detects the language of the latest user message (å/ä/ö or common Swedish words, else English) and adds an explicit "Reply in Swedish."/"Reply in English.". Replay test `/tmp/langtest2/run4.py` checks whether an explicit directive overrides history, placed as a system turn before the reply (S) or appended to the last user turn (U).

Result: S and U both 20/20 (S's one "miss" was Swedish without å/ä/ö, a checker false negative). Baseline L0 again 0/5 on Swedish-after-English history. Implemented S in `zeroclaw-qwen3.6.jinja` (not built or switched): before the generation prompt the template takes the latest real user message, keeps only the text after ZeroClaw's `...:00] ` timestamp, and emits a system turn "Reply in Swedish." if it has å/ä/ö or a common Swedish word (hej, tack, och, jag, inte, vad, hur, ...), else "Reply in English.". Uses only `split`, `lower`, `replace` and namespaces; llama.cpp's Jinja parser not verified locally (no jinja2 here). Also emitted before tool-call decisions (iteration 1), which the replay did not test.

Switched desktob: the template loads, but every request fails with HTTP 500 "The model produced output that does not match the expected peg-native format". llama-server derives its output parser from the generation prompt, and the extra system turn there breaks it. The bot is down until the next switch. Plan: move the directive into the latest real user message (stable across renders, generation prompt untouched). Replay `/tmp/langtest2/run5.py` tests that position (Q); it strips the live template's broken directive from `/apply-template` output.

Result: Q 20/20, no directive 10/20. Implemented (not switched): the generation prompt is back to the original, the language check runs before the message loop, and "Reply in Swedish."/"Reply in English." is appended to the content of the latest real user message (`ns.last_query_index`). The S version parsed and loaded in llama.cpp, so the Jinja features used are supported. Side effect: when a new user message arrives, the previous one loses its directive, so the prompt cache is reused only up to that earlier message. Test `/tmp/langtest2/run2.py` (renders via `/apply-template`, edits, sends to `/completion`) is ready. Also seen: "Släck taklampan" first failed with `name: ceiling light` (HA has no Swedish alias for the entity), then succeeded on retry.

Final result (desktob switched 2026-11-22): Telegram after `/new`: "Släck alla lampor", "Tänd alla lampor", "Turn off all lights in the Livingroom", "Tänd taklampan" answered Swedish, Swedish, English, Swedish. No emojis, no errors. Template maintenance: `zeroclaw-qwen3.6.jinja` is a copy of the Unsloth Qwen3.6 template; re-diff it against `/props?model=zeroclaw` (with the custom file removed) when the model or GGUF changes. The ZeroClaw timestamp format (`[... +01:00] `) is what the language check splits on; a ZeroClaw upgrade could change it.

## English-only replies: evaluation (2026-11-22, not decided)

Idea: the assistant always replies in English (text and speech) while still understanding Swedish (Swedish STT stays).

| Part | Today | English-only |
|---|---|---|
| Chat template (`modules/ai/_files/zeroclaw-qwen3.6.jinja`) | System line "reply in the user's language" plus a per-message "Reply in Swedish/English." picked by a language check (timestamp split, å/ä/ö, word list) | Fixed line "Always reply in English" and a fixed "Reply in English." on the latest user message. The language check (about 20 lines, the fragile part: depends on ZeroClaw's timestamp format, misreads Swedish without markers, and the HA component's English greeting note) goes away. The custom template stays: the per-message line is what beats the history effect, and "No emojis" counters ZeroClaw's Telegram prompt |
| `SOUL.md` language section | Four rules | One line |
| `script.announce` | `language` field, voice map sv/en | Always `en_GB-jenny_dioco-medium`; one field less in the tool schema |
| Assist pipeline TTS | `sv_SE-alma-medium` (the user finds it poor) | `en_GB-jenny_dioco-medium` |
| HA local intents | Swedish sentences matched, replies in Swedish | Conflict: HA's own replies are in the pipeline's conversation language. Keeping Swedish means Jenny reads Swedish (garbled). Setting the conversation language to English means Swedish speech never matches a local intent and everything goes to ZeroClaw (a few seconds slower, loses the offline fallback for lights) |
| Swedish entity and area aliases, Swedish STT, Telegram voice notes | Needed | Still needed (Swedish input) |

Risk: the model replying in Swedish anyway when the user and history are Swedish. The replay tests showed that a per-message "Reply in X." on the latest user message overrode history 20/20 in both directions, so a fixed "Reply in English." should hold; verify live after the change.

Decided 2026-11-22: English-only, HA sentence matching off. Done: pipeline renamed "ZeroClaw", `prefer_local_intents: false`, TTS `en_GB-jenny_dioco-medium` (STT stays Swedish); `script.announce` has no `language` field and always uses Jenny (HA config repo `0fd31b9`, played on the living room speaker); chat template: fixed system line "Always reply in English, also when the user writes Swedish. No emojis." and a fixed "Reply in English." on the latest user message, language check removed; `SOUL.md` language section is one line. Template and `SOUL.md` need desktob and hyllan switches. Switched and verified by the user (Telegram, Assist, announcements all English). Assist still produced emojis, which TTS spells out; the per-message line is now "Reply in English, without emojis." (needs a desktob switch). Fallback if that is not enough: strip emojis deterministically before TTS. After the desktob switch: no emojis. New issue: "Tänd taklampan i vardagsrummet" through Assist: the first `HassTurnOn` failed because the model passed `device_class` (HA: "No entities matched the device class"), it retried with only the area and turned on every living room light, and its narration ("Let me try without specifying the device class.") was glued to the answer. `SOUL.md` "Home" got three rules: name plus area for a single light and never `device_class`; no wider retry after a failure; no narration of tool calls (needs a hyllan switch). Next Assist test (trace copied to `/tmp/zc-trace4/`): "Släck takrampan" (STT misheard) failed correctly in HA, the retry with `taklampan` worked; "Tänd taklampan" made no tool call and repeated the earlier failure text from history. Direct MCP calls confirm HA matches the alias (`name: taklampan, area: vardagsrummet`, with or without `domain`; `device_class` gives "invalid slot info"). Fix (needs desktob and hyllan switches): the per-message line is now "Reply in English, without emojis. For any action, call the tool now; earlier results in this conversation do not count.", and `SOUL.md` Honesty forbids reusing an earlier failure. STT misrecognitions of names could be reduced with faster-whisper's HA name biasing (`--hass-token`).

After those switches: better, but one Swedish text reply and narration again. Text replay through the Assist agent (3 runs of "Tänd takrampen" then "Släck taklampan" in one conversation): second reply English 3/3; narration before the tool call ("I'll turn on the ceiling ramp light in the living room now.") 3/3. ZeroClaw's `/ws/chat` always streams chunks, including pre-tool text, then `done` with the final answer (`ws.rs`); there is no setting to stop that, and the component speaks the chunks. Option 1 chosen: per-message line extended with "Write nothing before a tool call." (needs a desktob switch). Fallbacks: patch the component to speak only `done.full_response`, or ask upstream for an option.

Result after the desktob switch (same 3-run replay): narration gone in 2 of 3 first replies, but run 1 returned the model's reasoning as the answer ("The user wants me to turn on the ceiling light ... I need to use the HassTurnOn tool"), and run 2's "Släck taklampan" switched off every living room light despite the `SOUL.md` rule (the test turned off four lights; restored). Conclusion: piling rules into the per-message line degrades the 35B-A3B model's behaviour. Next: revert that line to "Reply in English, without emojis." plus at most the tool-honesty rule, and fix narration in code (component patch).

Done: template per-message line reverted to "Reply in English, without emojis." (needs a desktob switch). Component patched (local, not upstream): `custom_components/zeroclaw_conversation/api.py` `async_stream_ws_chat` buffers chunks, clears them on a `tool_call` frame, and yields the remaining text (or `full_response`) on `done`; the original is at `/mnt/tank/services/hass/home-assistant/zeroclaw_conversation-api.py.orig`, patched sha256 `6841c829...`. A Marketplace update to the component overwrites the patch: re-apply it or skip updates. HA restarted (10 s, no light or button changes). Read-only replay (6 runs: "Vilka lampor är tända i vardagsrummet?", "Vad är klockan?"; desktob not yet switched): no narration. Cosmetic leftovers: the component's first-turn greeting ("Hi Agent", the test account), Markdown bold in lists (spoken by TTS), alias pairs like "Julgran/Julgranen", one wrong weekday.

Net: a moderate simplification (the language check, the bilingual persona rules, the voice choice) plus better-sounding speech, at the cost of HA local intents (or Swedish replies from them). Suggested if the change is wanted: template + `SOUL.md` + `announce` + pipeline voice together, and decide local intents separately (off, so everything goes through ZeroClaw in English, or keep Swedish local replies with a Swedish voice only for those).

## Telegram voice replies: plan (2026-11-22, not implemented)

Status (2026-11-27): disabled (`tts.enabled = false` in `zeroclaw.nix`, needs a hyllan switch) because Telegram does not autoplay voice messages. The `tts-bridge` unit, `providers.tts.openai.home` and the agent `tts_provider` are kept; set `tts.enabled = true` to re-enable.

ZeroClaw 0.9.0 facts (`telegram.rs`, `tts.rs`, `schema.rs`): with `tts.enabled = true` and an agent `tts_provider`, the Telegram channel answers with audio when the session is in voice mode (the user sent a voice note) or the chat is a configured voice peer; typed messages stay text. `voice_reply_skip_reason` skips URLs, JSON, code and short status text. Audio format decides the Telegram call: `opus`/`ogg` goes out as `sendVoice` (a voice bubble), `mp3`/`wav` as `sendAudio` (a file with a player). The `piper` provider expects an OpenAI-style HTTP endpoint and always yields WAV; the `openai` provider takes `uri`, `model`, `voice`, `speed`, `response_format` and a required `api_key` (sent as a bearer token). Our Piper is Wyoming only, so ZeroClaw cannot use it directly.

Plan (option 1, an adapter):
1. `tts-bridge` on hyllan: a small Python service (`modules/hosts/hyllan/_files/tts-bridge/tts_bridge.py`, stdlib `http.server` plus nixpkgs `python3Packages.wyoming`, ffmpeg) on `127.0.0.1:10210`. `POST /v1/audio/speech` with `{input, voice, response_format}`: strip Markdown, send a Wyoming `synthesize` request to Piper on `127.0.0.1:10200` (voice from the request, default `en_GB-jenny_dioco-medium`), collect the PCM chunks, encode with ffmpeg to Ogg/Opus (or mp3/wav if asked) and return it. Talking to Piper directly avoids an HA token and keeps it working when HA restarts. Systemd unit with the same sandbox as the other services, `DynamicUser`, localhost only, logs readable via agent-logs.
2. `zeroclaw.nix`: `tts.enabled = true`; `providers.tts.openai.home = { uri = "http://127.0.0.1:10210/v1/audio/speech"; api_key = "local"; voice = "en_GB-jenny_dioco-medium"; response_format = "opus"; }`; `agents.assistant.tts_provider = "openai.home"`. The key is a placeholder the bridge ignores (localhost only).
3. Test: `curl` the bridge on hyllan and check the Ogg file with ffprobe; then a Telegram voice note, expecting a voice bubble in Jenny's voice next to the text reply; a typed message must stay text only.

Open: whether ZeroClaw sends the voice bubble in addition to or instead of the text; how long replies are cut (`tts.max_text_length`, default 4096).

Implemented (not switched): `modules/hosts/hyllan/tts-bridge.nix` and `_files/tts-bridge/tts_bridge.py` (`git add -N`), unit `tts-bridge` (python3 with `wyoming`, `ffmpeg-headless` on PATH, sandboxed, `127.0.0.1:10210`, agent-logs). `zeroclaw.nix`: `tts.enabled`, `providers.tts.openai.home`, agent `tts_provider = "openai.home"`. Checked locally with fake PCM: imports resolve, Markdown cleanup works, opus/mp3/wav encode (OggS, ID3, RIFF headers). hyllan switched: `tts-bridge` active; a request with Markdown returned HTTP 200, 12 kB `audio/ogg` (Opus, 48 kHz, 2.9 s) in 244 ms.

Telegram test (trace in `/tmp/zc-trace5/`): every voice note got a voice reply except "It's 23:01 on Sunday, November 22, 2026." (40 bytes; `MIN_VOICE_REPLY_BYTES = 40`, hardcoded, `too_short`), each about 10 s after the text. The delay is a hardcoded debounce on the normal send path (`try_queue_voice_reply` with `immediate = false`, sleep 10 s, "coalesce multi-part tool-chain responses"). Voice mode is cleared after each voice reply, so typed follow-ups stay text (by design). Telegram does not autoplay voice messages (client behaviour; "Raise to Listen" on iOS is the closest). Lever to test: `channels.telegram.home.stream_mode = "partial"` takes the finalize path that queues voice with `immediate = true` (no 10 s wait); `multi_message` would post narration as separate permanent messages, so not that one. Speech recognition on this path also misheard ("Var där klockan", "Vilka lampor jag tänder", "Täm taklampan"). Changed (not switched): `stream_mode = "partial"` on `channels.telegram.home` (hyllan), and desktob's whisper-server `language = "sv"` instead of auto.

Stronger STT models (2026-11-22, proposal): KBLab KB-Whisper (Swedish fine-tunes of OpenAI Whisper, 50,000 h of Swedish). Swedish WER from the model card (FLEURS / CommonVoice / NST): KB large 5.4 / 4.1 / 5.2 vs OpenAI large-v3 7.8 / 9.5 / 11.3; KB medium 6.6 / 5.4 / 5.8; KB small 7.3 / 6.4 / 6.6 vs OpenAI small 20.6 / 26.4 / 26.4. `large-v3-turbo` is a pruned large-v3 (4 decoder layers), not in the table, likely somewhat worse than large-v3. Formats per repo: GGML for whisper.cpp (`ggml-model.bin`, large 3.1 GB; `ggml-model-q5_0.bin`, large 1.1 GB) and CTranslate2 (`model.bin` plus tokenizer, loadable by faster-whisper as `KBLab/kb-whisper-<size>`). Proposal: whisper-server (Telegram, GPU) to KB large GGML; faster-whisper (Assist, CPU) to KB small (better Swedish than OpenAI large-v3 by these numbers, and faster than turbo on CPU) or KB medium. Trade-off: KB models are tuned for Swedish; English recognition may get worse. Implemented (not switched): whisper-server model `KBLab/kb-whisper-large` `ggml-model.bin` pinned to commit `d5d5984b` (sha256 `b66f2dda...`, 3.1 GB, fetched at build time); faster-whisper `model = "KBLab/kb-whisper-small"` (CTranslate2, downloaded to the persisted dir on first start, unpinned; the repo was at `3564d61a` on 2026-11-22). Both hosts switched: whisper-server loaded KB large on ROCm (3094 MB); faster-whisper downloaded KB small and is ready. Clean Piper test sentences ("Tänd taklampan i vardagsrummet.", "Vilka lampor är tända just nu?"): whisper-server 0.5 to 0.8 s per request from hyllan, Assist pipeline 0.75 s from speech end to text (was 3.1 s with turbo); both transcripts correct apart from "tacklampan" (the same with every model).

User test: Assist correct (recognition, English, no emojis). Telegram voice bubbles now arrive with the text (`partial` removed the 10 s wait), but replies to voice notes were Swedish with "💡" while the first reply in the session was English. Trace (`/tmp/zc-trace6/`): Telegram system prompt 17,031 chars vs 15,220 over the gateway (ZeroClaw's Telegram block), Telegram session fresh at 22:20; prompt content not logged. Temporary `observability.log_llm_request_payload = "full"` added to `zeroclaw.nix` (marked TODO, remove after the comparison).

Comparison (trace `/tmp/zc-trace7/`): a fresh Telegram session gave four English replies without emojis, so the Swedish replies are intermittent (the failing session started with a light list full of Swedish names, then copied that style). The logged messages are pre-template, so the per-message directive is not visible there. Finding: ZeroClaw created default workspace files at first start (`AGENTS.md`, `TOOLS.md`, `USER.md`, `MEMORY.md`, `HEARTBEAT.md`), injected into every prompt; `USER.md` still had placeholders ("Name: User", "Timezone: UTC", "Use occasional relevant emojis (1-2 max)"). Telegram also adds "Use emoji naturally to add personality" (built in). Fix (needs a hyllan switch): `USER.md` managed from Nix (`_files/zeroclaw/USER.md`, bind-mounted read-only like `SOUL.md`): Tobias, Europe/Stockholm, speaks Swedish and English, replies in English, short, no emojis, no Markdown for simple answers. Payload logging removed again. hyllan switched; user verified in Telegram (light list, voice notes): English, no emojis, no Markdown. Committed (`1a78ab3`, `66a3dfa`, `c62f451`, `9308e51`). Temporary files deleted, including the traces and the component clone (`/tmp/review-hazc`); to re-apply the component patch after an update, fetch the repo again and redo the `api.py` change described above.

## Decisions

| Topic | Choice |
|---|---|
| Framework | ZeroClaw 0.9.0 |
| Host | hyllan (always on, 12 cores, 30 GB RAM, same host as HA) |
| Model | Local Qwen3.6-35B-A3B via `llama-server` on desktob (private agent). See "Local model and privacy" |
| Chat channel | Telegram (default feature build, long polling, no public URL) |
| Language | Swedish by default, English when spoken or written to in English |
| Home Assistant | HA `mcp_server` integration, "Device control" set only |
| Voice | Phase 4 Telegram voice memos, Phase 5 HA Assist |

Superseded by the local-first decision below: the OpenRouter model is now only for an optional second, non-private agent. Details of that model: tool calling, 1M context, $0.036/M input, $0.50/M output. The dated id is pinned; the undated alias is cheaper on output ($0.20/M) but moves. Prompts and HA states go to OpenRouter and its upstream provider; set the account's data policy (no training / ZDR) if that matters.

## Target capabilities (end vision, 2026-11-21)

Examples: "Stäng av alla lampor på nedervåningen", "Spela blandad Depeche Mode på kontorshögtalaren", "Hur många arbetstimmar har jag loggat denna månad?". Plus knowledge of the user's documents, and spoken replies as announcements on HA speakers.

| Capability | Mechanism | Phase | Open |
|---|---|---|---|
| Lights by room or floor | HA MCP "Device control" (`HassTurnOff` takes area, floor, domain) | 3 | HA floors/areas must be set up and entities exposed |
| Music on a named speaker | HA script exposed to Assist, e.g. `play_music(query, player)` calling `music_assistant.play_media` (radio mode for "mixed"); scripts appear as MCP tools | 3b | Verify scripts are exposed as MCP tools and that HA's built-in media search intent works with Music Assistant |
| Work hours from the Obsidian vault | Notes exist on desktob and laptob (synced). Add hyllan as a receive-only Syncthing device for `Work`, ZeroClaw reads it via `bindReadOnlyPaths`; hours are a table in daily notes, summed by a deterministic parser tool (not the LLM) | 6 | Exact table format and file naming; whether ZeroClaw supports stdio MCP servers or script tools for the parser |
| Knowledge of documents | Start with grep/read tools over the read-only folders. Embedding index (local embedding model on desktob) only if that proves too weak | 6 | Which folders are in scope; whether ZeroClaw memory supports local embeddings |
| Spoken replies | HA script `announce(message, speaker)` using `tts.speak` with a local Piper voice (`sv_SE-nst-medium`) on a Sonos/media player; exposed as an MCP tool | 4b | Piper on hyllan (Wyoming), Sonos fetching the TTS URL from HA |
| Voice in | Telegram voice memos (phase 4), HA Assist satellite (phase 5) | 4, 5 | How HA Assist reaches ZeroClaw (community component, or webhook channel) |

Constraints: 32k context shared by system prompt, tool schemas and history, so keep the tool set small (HA scripts instead of many tools, no unused MCP servers). Everything stays local, so the vault and documents are fine to expose to the private agent but never to a cloud `researcher` agent.

## Alternatives considered (2026-11-21)

A from-scratch agent on Pi and `@earendil-works/pi-durable` was researched (notes in `/tmp/research-pi-durable.md`, not kept). Pi Durable is an experimental TypeScript library (durable turns, exactly-once intake, durable timers, approval signals since 1.6.0) with frequent breaking changes, and no Telegram, cron, cost guard or sandbox. The third-party `pi-durable-telegram` has bash always on and cloud voice (Deepgram). Decision: keep ZeroClaw for phases 1 to 3. Revisit a custom Pi Durable service only if its API stabilises or ZeroClaw proves unreliable.

## Local model and privacy (decided 2026-11-21)

- Goal: local data (HA states, memory, chat) never leaves the LAN/wg network.
- Main agent `assistant`: model provider is an OpenAI-compatible endpoint on desktob. No OpenRouter fallback. If desktob is unreachable the assistant is down (private by design).
- desktob becomes always-on (suspend off). It is a gaming workstation: GPU/VRAM is shared with the model, so gaming and the model compete. Needs a decision on `wake-guard` and suspend settings.
- Optional second agent `researcher` on OpenRouter with no HA bundle and no memory. The private agent delegates only sanitized, self-contained questions. Not required for phase 1.
- Transport: hyllan (wg0 `10.64.1.2`, hub) to desktob (wg0 `10.64.1.6`). llama-server listens on the wg interface only, not tailnet and not LAN.

### What exists on desktob

- `modules/ai/llama-cpp.nix`: `antob.llama-cpp.runAsService` (default false) runs `services.llama-cpp` in router mode with `models-preset`. `host = "127.0.0.1"`, `port = 8080` are hardcoded, no API key, no firewall rule. Preset `qwen3.6-35B` exists (`UD-Q4_K_XL`, `ctx-size = 262144`, `models-max = 2`).
- desktob uses `pkgs.llama-cpp-vulkan`, not enabled as a service yet.
- Pattern to copy: `modules/ai/ollama.nix` has `host` and `openFirewallInterfaces = [ "wg0" ]` options (desktob sets `0.0.0.0` plus `wg0`). `clipperd` instead uses `bindIp = wgIp`.

### Implemented on desktob (2026-11-21, uncommitted, not yet built or switched)

- `modules/ai/llama-cpp.nix`: options `host`, `port`, `openFirewallInterfaces`, `apiKeyFile`. The key goes to the DynamicUser service through `LoadCredential` and `--api-key-file`. Firewall opens the port on the listed interfaces only. `/var/cache/private/llama-cpp` is persisted so model downloads survive reboots (unverified that preservation handles the `private` path like ollama's).
- New router preset `zeroclaw`: same Qwen3.6-35B-A3B `UD-Q4_K_XL`, `ctx-size = 32768`, `parallel = 1`, `reasoning = off`, `no-mmproj = true`. Not in `loadOnStartup`. Preset keys `parallel` and `no-mmproj` are unverified in the router ini.
- desktob: `runAsService = true`, `host = 0.0.0.0`, firewall on `wg0` only, `llama_api_key` secret from `desktob/secrets.yaml` (raw value, same as `LLAMA_API_KEY` in hyllan's `zeroclaw_env`). Models load on first request, nothing preloaded. Wake and suspend config untouched.
- Request with `"model": "zeroclaw"` against `http://10.64.1.6:8080/v1` and `Authorization: Bearer <key>`.

### Original change list (superseded by the above)

1. llama-cpp aspect: make `host`, `port` and `openFirewallInterfaces` options, add API key (`--api-key` from a sops secret, in `extraFlags` or settings). Set `runAsService = true` and `loadOnStartup = [ "qwen3.6-35B" ]` on desktob.
2. Bind choice: `host = "0.0.0.0"` with the firewall opened only on `wg0` (matches ollama, no start ordering issue), or `host = "10.64.1.6"` which fails if `wg-quick-wg0` is not up yet and needs `after`/`requires` on it. Recommended: 0.0.0.0 plus `wg0`-only firewall rule.
3. ZeroClaw provider: OpenAI-compatible with `base_url = "http://10.64.1.6:8080/v1"` and the API key from `zeroclaw_env`. Verify the provider type and `base_url` field name in `zeroclaw config schema`.
4. desktob: disable suspend (and check `wake-guard`), model preloaded at boot.

### Tool calling test results (2026-11-21, desktob, `-c 32768 --jinja`, one-tool schema, Swedish prompt)

| Mode | Valid tool calls | Time for 40 runs |
|---|---|---|
| thinking on | 39/40 (the failure: `finish_reason: length`, empty content, runaway thinking; an earlier run had one plain-text answer) | 916 s (about 23 s each) |
| thinking off (`chat_template_kwargs.enable_thinking=false`) | 40/40 | 35 s (about 0.9 s each) |

Service preset check (2026-11-22, `model = zeroclaw` through the router on desktob, API key, `reasoning = off` from the preset only): 20/20 valid, 18 s total. Preset `parallel` and `no-mmproj` keys were accepted.

Layer 4 (2026-11-22, real HA tool list from `/api/mcp/assist`, 21 tools, 9.9 kB, 3.2k prompt tokens with a short system prompt, 3 runs per prompt):
- Correct: "Släck alla lampor på nedervåningen" -> `intent__HassTurnOff {floor: nedervåningen, domain: [light]}` (3/3). Two-action prompt gave two parallel calls (3/3). State reads use `homeassistant__GetLiveContext` (6/6). Time uses `llm__GetDateTime` (3/3). No-tool question gave no call (3/3). Answers in the user's language.
- Problems: (1) "Tänd lampan i köket" called `assist_satellite__HassBroadcast` instead of turning on in 1/3. (2) "Turn off all the lights upstairs" passed `area: upstairs` instead of `floor` (3/3). HA's template `area_id('upstairs')` is None while `floor_id('upstairs')` is `upper_floor`, so this may not resolve; unverified against the intent. (3) `domain` is sent as a string in some calls and a list in others; unverified whether HA accepts both.
- Tool set also has `media_player__search_media` and `media_player__play_media` (music) and `media_player__HassSetVolume*`. No scripts yet.
- Mitigations to try: `excluded_tools` for `assist_satellite__HassBroadcast` and other unused tools (`HassCancelAllTimers`, `todo__*`, `HassBroadcast`), and a system prompt hint (use `floor` for Downstairs/Nedervåningen/Upstairs/Övervåningen, `area` for rooms).

Decision: thinking off by default, set server side in the preset (ZeroClaw is unlikely to send per-request template kwargs). Still to test: real HA tool schemas (layer 4), multi-call prompts and the tool-result round trip.

### Things to verify

- Tool calling quality of Qwen3.6-35B-A3B through llama-server (`--jinja`, chat template) on multi-step MCP calls. Test before relying on it.
- `ctx-size = 262144` is too large to need here. ZeroClaw system prompt plus HA tool schemas is large but 32k to 64k is likely enough. Lower it to free VRAM for gaming, and measure.
- Whether `qwen3.6-35B` reasoning output (thinking) is handled correctly by ZeroClaw, or needs disabling in the preset.
- Telegram voice (phase 4) is unaffected: whisper stays on hyllan.

## Packaging

- No nixpkgs module. Upstream ships `nix/module.nix`: `services.zeroclaw.instances.<name>` with `settings` (freeform TOML), `environmentFile`, `dataDir`, `bindReadOnlyPaths`, `extraConfig`, `package`, `webUiPackage`.
- Packages: nixpkgs 0.8.4 (cached, but older schema). llm-agents 0.9.0 with default features (Telegram, Discord, email, webhook, filesystem, ACP). Upstream flake 0.9.0 with a wide feature set via fenix. Neither 0.9.0 build is in a configured cache, so hyllan compiles it once (and the nightly cache build keeps it warm).
- Plan: flake input `zeroclaw = { url = "github:zeroclaw-labs/zeroclaw/v0.9.0"; flake = false; }`, import `"${inputs.zeroclaw}/nix/module.nix"`, set `package = inputs.llm-agents.packages.${system}.zeroclaw`. Bump input and llm-agents together; the module and the binary should agree on the schema.
- `webUiPackage`: leave at default (`null` without the upstream overlay). The llm-agents build embeds `web/dist` in the binary anyway; the gateway stays on `127.0.0.1:42617` with pairing on. Reach it over an SSH tunnel if needed.

### What the module does

- One unit `zeroclaw-<name>.service`, system user/group `zeroclaw-<name>`, `dataDir` created by tmpfiles (mode 0750), `ReadWritePaths = [ dataDir ]`.
- `ExecStartPre` runs `envsubst` over the rendered TOML into `${dataDir}/config.toml` (0600). `$VAR` in `settings` strings come from `environmentFile`. The unit has `ConditionPathExists` on the env file, so it stays inactive (not failed) until sops has decrypted it.
- The config is re-rendered on every start: edits made via dashboard or `zeroclaw config set` are lost. Nix is the source of truth.
- Hardening: `ProtectSystem=strict`, `ProtectHome`, `PrivateUsers`, `PrivateDevices`, `MemoryDenyWriteExecute` (fine for the llm-agents build, which has no WASM JIT plugins), only `AF_INET`/`AF_INET6`/`AF_UNIX`.
- `ZEROCLAW_WORKSPACE = ${dataDir}/workspace` is set by the module, while the 0.9.0 docs describe `agents/<alias>/workspace`. Check which layout the first start actually creates before binding identity files.

## Config facts that matter (0.9.0)

- `schema_version = 4` must be set (the module does not add it).
- Every agent needs `model_provider`, `risk_profile` and `runtime_profile`, all resolving to configured entries, or startup fails.
- Telegram authorization: `peer_groups.<name> = { channel = "telegram.home"; agents = [ "assistant" ]; external_peers = [ "<numeric id>" ]; }`. The `allowed_users` key in upstream's README example is gone.
- `OPENROUTER_API_KEY` is read from the environment natively; it only needs to be in the env file.
- Autonomy (`risk_profiles.<name>.level`): `readonly`, `supervised` (default), `full`. Under `supervised`, every MCP tool call asks for approval (Telegram inline buttons) unless its prefixed name is in `auto_approve`. `always_ask` overrides everything. `excluded_tools` removes tools on non-CLI channels.
- `allowed_tools` non-empty auto-admits all MCP tools (`<server>__<tool>`); blocking an MCP tool needs `excluded_tools`.
- MCP servers are only connected for agents with matching `mcp_bundles` (deny by default). HTTP transport supports `headers` (Bearer token).
- Scheduling: built-in `cron_add` / `cron_list` / `cron_remove` tools (the agent can set reminders from chat) and declarative jobs (`job_type = "agent"`, `prompt`, `schedule`, `delivery`).
- Cost guard: `cost.daily_limit_usd` (default 10), `cost.monthly_limit_usd` (default 100).
- Personality: `openclaw` identity format, i.e. `IDENTITY.md` / `SOUL.md` in the agent's workspace. This is where "answer in Swedish by default" goes. `locale` only changes ZeroClaw's own UI strings.
- Transcription: `local_whisper` posts multipart `file` only (no language field) and expects JSON `{ "text": ... }`. That matches whisper.cpp's `whisper-server` `/inference` endpoint. Language therefore has to be set server-side (`-l auto` or `-l sv`).

## hyllan conventions

- hyllan imports `common`, no impermanence. Data under `/mnt/tank/services/<name>` on `zpool/tank`, backed up by the `tank` restic entry in `backup.nix` via an explicit `paths` list (vaultwarden, mass, caddy, esphome, freshrss). ZeroClaw fits there: `dataDir = "/mnt/tank/services/zeroclaw"`, add `"/services/zeroclaw"` to that list. No new dataset needed.
- Secrets: one sops env file per service (`zeroclaw_env`), like `searxng_env`, `vaultwarden_env_variables`.
- HA runs with `--network=host`: `http://127.0.0.1:8123` from the host.

## Draft settings (sketch, not final)

```nix
services.zeroclaw.instances.assistant = {
  package = inputs.llm-agents.packages.${system}.zeroclaw;
  dataDir = "/mnt/tank/services/zeroclaw";
  environmentFile = secrets.zeroclaw_env.path; # OPENROUTER_API_KEY, TELEGRAM_BOT_TOKEN, HA_TOKEN
  settings = {
    schema_version = 4;
    providers.models.openrouter.default.model = "deepseek/deepseek-v4.1-flash-1017";
    agents.assistant = {
      model_provider = "openrouter.default";
      risk_profile = "assistant";
      runtime_profile = "assistant";
      channels = [ "telegram.home" ];
      mcp_bundles = [ "home" ];                         # Phase 3
      # transcription_provider = "local_whisper.default"; # Phase 4, field name to verify
    };
    risk_profiles.assistant = {
      level = "supervised";
      auto_approve = [ "ha__<read tool>" ];             # Phase 3, names verified after connect
    };
    runtime_profiles.assistant = { };
    channels.telegram.home = { enabled = true; bot_token = "$TELEGRAM_BOT_TOKEN"; };
    peer_groups.telegram_home = {
      channel = "telegram.home";
      agents = [ "assistant" ];
      external_peers = [ "<telegram user id>" ];
    };
    cost = { daily_limit_usd = 2.0; monthly_limit_usd = 20.0; };
    mcp.servers = [ {                                   # Phase 3
      name = "ha";
      transport = "http";
      url = "http://127.0.0.1:8123/<path from HA UI>";
      headers.Authorization = "Bearer $HA_TOKEN";
    } ];
    mcp_bundles.home.servers = [ "ha" ];
  };
};
systemd.services.zeroclaw-assistant.serviceConfig.MemoryMax = "1G";
```

## Phases

### Phase 1: Home Assistant and secrets (user, UI only)

1. Create a non-admin HA user `zeroclaw` and a long-lived access token for it.
2. Settings > System > AI: enable Model Context Protocol, AI tools = "Device control" only. Copy the Main URL (path goes into the MCP server entry).
3. Expose lights (and anything else the agent may see) on the voice assistants exposed-entities page.
4. Create a Telegram bot with BotFather; note your numeric Telegram user id.
5. Add `zeroclaw_env` to hyllan `secrets.yaml`: `OPENROUTER_API_KEY`, `TELEGRAM_BOT_TOKEN`, `HA_TOKEN`.

### Phase 2: ZeroClaw base service

1. Flake input `zeroclaw` (`flake = false`, tag `v0.9.0`).
2. `modules/hosts/hyllan/zeroclaw.nix` adding to the `hyllan` aspect: module import, instance per the sketch without the MCP and transcription parts, `sops.secrets.zeroclaw_env` owned by `zeroclaw-assistant`, `MemoryMax`.
3. `backup.nix`: add `"/services/zeroclaw"` to the `tank` paths.
4. After first start: inspect the workspace layout, then write `IDENTITY.md` / `SOUL.md` (name, Swedish by default, English when addressed in English, short answers). Decide whether to manage them from Nix via `bindReadOnlyPaths` (read-only, declarative) or leave them agent-editable.
5. Test: text chat in both languages, "påminn mig om 5 minuter" (cron tool), restart survives memory.

### Phase 3: Home Assistant via MCP

1. Add the `ha` MCP server and `home` bundle.
2. List the discovered `ha__*` tools (dashboard or logs). Put the state-reading tool(s) and `ha__GetDateTime` in `auto_approve`; control tools then ask on Telegram before acting. Alternative: put control tools in `excluded_tools` for strict read-only.
3. Test: "Vilka lampor är tända?", "Which lamps are on?".

### Phase 4: Telegram voice memos

1. whisper.cpp `whisper-server` as a small systemd unit on hyllan (no nixpkgs module exists), bound to `127.0.0.1`, `-l auto`, ~8 threads. Model fetched with a pinned hash from Hugging Face.
2. Model choice, to test on real memos:
   - `ggml-large-v3-turbo-q5_0` (multilingual, best quality per CPU second): recommended start.
   - `ggml-medium` (multilingual, slower, weaker Swedish).
   - KBLab `kb-whisper` (Swedish fine-tune, best Swedish, weaker English; would need `-l sv`).
   - Short clips can trip auto-detect; if Swedish is misdetected often, force `-l sv` and accept weaker English.
3. Transcription provider `local_whisper` -> `http://127.0.0.1:<port>/inference`, attach to the agent.
4. Optional: TTS replies with the Piper provider (Swedish voice `sv_SE-nst-medium`).

### Phase 5: HA Assist voice (optional)

1. Wyoming services on hyllan (`services.wyoming.faster-whisper`, `piper`, `openwakeword`), ESPHome satellite or HA companion app.
2. HA's local intents handle direct commands; optionally route other requests to ZeroClaw via the community `ha-zeroclaw-conversation` component (unvetted).
3. Two STT stacks (whisper.cpp for ZeroClaw, faster-whisper for HA) is acceptable; unify later only if RAM becomes a problem.

## Later ideas

- Reminder for the user (asked 2026-11-22): evaluate having the assistant always reply in English (text and speech) and list what that would simplify (the language check in the chat template, the `SOUL.md` language rules, Swedish TTS voice selection, per-language pipelines). Swedish speech recognition stays required.

- GLaDOS-style voice (user wish, 2026-11-22). Options: a community Piper/VITS GLaDOS model (English only, drop-in `.onnx` + `.json` for Piper); an effects chain on the normal voice (pitch, flattening, slight ring modulation and reverb via sox/ffmpeg, works for Swedish, needs a small Wyoming wrapper or HA-side processing); or Swedish Piper output fed through an RVC voice-conversion model of GLaDOS (Swedish words in her timbre, best fit on desktob's GPU). Fan-made models trained on game audio: fine for home use, not for redistribution.

- Declarative morning brief: cron job (`job_type = "agent"`) at 07:00 delivered to Telegram (weather, calendar, electricity price from HA).
- Web search via an MCP server (searxng runs on hyllan already).

## Phase 1 status (2026-11-21)

Done:
- HA user `assistant` (non-admin) and a long-lived token. MCP server integration enabled. Use the Device control URL `/api/mcp/assist` (works for non-admin, ignores Main URL options). Bearer auth with the long-lived token was tested with curl against `tools/list` and works.
- Entities exposed to Assist. Swedish aliases added to all areas and floors (registry backup in `/tmp/registries-2026-11-21`, not kept).
- Speakers are in living room, kitchen and upstairs hall (no office area). Music target is the room name.
- Telegram bot `@antob_home_bot` (display name "Assistant"), groups disabled. Telegram user id: `8660620274`.

Left: add `zeroclaw_env` to hyllan `secrets.yaml` with `OPENROUTER_API_KEY` (only if the cloud agent is used, otherwise omit), `TELEGRAM_BOT_TOKEN`, `HA_TOKEN`, and the llama-server API key.

## Phase 2 draft (2026-11-22, uncommitted, not built)

- `flake.nix`: input `zeroclaw` (tag v0.9.0, `flake = false`). `flake.lock` gained only that entry.
- `modules/hosts/hyllan/zeroclaw.nix`: imports upstream `nix/module.nix`, instance `assistant` with package from llm-agents 0.9.0, `dataDir = /mnt/tank/services/zeroclaw`, `environmentFile = zeroclaw_env`, provider `llamacpp.desktob` (`http://10.64.1.6:8080/v1`, model `zeroclaw`, `$LLAMA_API_KEY`), Telegram channel `telegram.home`, peer group for `8660620274`, risk level `supervised`, `MemoryMax = 1G`, agent-access log reading. No MCP, transcription or cost limits yet.
- `backup.nix`: `/services/zeroclaw` added to the `tank` paths.
- Evaluated with `nix eval` only. First build compiles ZeroClaw (Rust) since 0.9.0 is not in a cache.
- Unverified: whether ZeroClaw accepts plaintext `api_key` / `bot_token` from the rendered config (it may re-encrypt them into `config.toml` and `.secret_key` in the dataDir, which is fine but is then state).

## First run findings (2026-11-22)

- Base service works: Telegram -> ZeroClaw (hyllan) -> llama-server (desktob) -> reply. Layout: `agents/assistant/workspace/` (empty at first start, so the docs layout applies, not the module's `workspace` env), `data/`, `shared/`, `state/`. Startup banner: `Memory: none (auto-save: on)`, `Skills: zeroclaw-docs`, gateway on 127.0.0.1:42617 (a one-time pairing code is printed in the journal).
- A bare "Hej!" produced a prompt of about 16k tokens (12.8 s prompt eval at about 1245 tok/s). The second message answered in about 1 s thanks to the llama-server prefix cache (single slot, stable prompt). Default `max_context_tokens` is 32,000, equal to our whole context.
- First reply was in Danish: no persona files yet.
- Tuning applied in the draft: `excluded_tools` for shell, file_write, file_edit, git_operations, web and browser tools, screenshot, image_gen, pushover, weather, email; runtime profile `compact_context`, `deferred_builtin_tools`, `max_context_tokens = 24000`; `skills.prompt_injection_mode = "compact"`. To measure: first-request `n_tokens` in the llama-server log after restart.
- Persona: `IDENTITY.md` and `SOUL.md` in `modules/hosts/hyllan/_files/zeroclaw/`, bind-mounted read-only into the workspace via `bindReadOnlyPaths` (Swedish by default, English when addressed in English, never claim an action is done before the tool succeeded). Unverified: that systemd creates the file mount points inside the workspace.
- Result of the tuning (switched 2026-11-22): prompt dropped from about 16k to about 3.3k tokens. Each Telegram message produces two llama-server requests (3293 tokens -> 3 output tokens, then 3942 tokens -> 15 output tokens), the second without prefix reuse, so a reply takes about 5 to 6 s (about 2.4 s + 2.9 s prompt eval at about 1400 tok/s). Cause of the first request unknown (candidates: reply-intent classifier, deferred tool lookup). ZeroClaw's journal at default level shows no request detail.
- An English question ("What time is it?") got a Swedish reply. Either the persona files are not loaded or the Swedish history biased it. Bind mounts are only visible inside the unit's namespace (`nsenter -t <MainPID> -m cat <file>`).
- Trace findings (2026-11-22, `log_llm_request_payload = "full"`, read via `ssh hyllan.lan`): persona files are in the system prompt (11.3k chars, 4 tools). The second request per message is the reply-intent precheck (`agents.<alias>.precheck.enabled`, meant for groups). Language test replaying the real system prompt on llama-server (3 runs per prompt): English prompts answered in Swedish 11/12 with the first `SOUL.md`, 5/12 with a "reply in the user's language" rule, 2/12 when the Swedish example sentence was also removed (misses were "Hello, how are you?"). Swedish prompts were always answered in Swedish. Final `SOUL.md` uses the last wording plus an explicit English-greeting line, and the precheck is disabled. Emojis still appear sometimes despite the rule.
- Phase 3 draft: `ha` MCP server (`http://127.0.0.1:8123/api/mcp/assist`, `$HA_TOKEN` header) and bundle `home` granted to the agent, no exclusions or auto_approve yet (every tool call asks for approval under `supervised`). Payload logging kept on for now.
- Phase 3 first run (2026-11-22): tool names are `ha__<set>__<tool>` (for example `ha__intent__HassTurnOff`, `ha__homeassistant__GetLiveContext`), 27 tools attached in total. "Vilka lampor är tända?" and "Släck tv-lampan" worked. "Släck alla lampor på nedervåningen" hung: llama-server generated 13,228 tokens (about 5 min, 47 tok/s) until ZeroClaw's 300 s timeout cancelled it; ZeroClaw then retried and the identical prompt answered in 1.2 s (54 tokens). So this is an intermittent runaway generation, not a tool/floor problem. The queued next request ("upstairs") waited behind it (single slot).
- Cause candidate: the `zeroclaw` preset used the thinking-mode sampler (temp 0.6, top-p 0.95, no presence penalty). Qwen3.6 model card for non-thinking mode: temp 0.7, top-p 0.8, top-k 20, min-p 0, presence_penalty 1.5 ("adjust presence_penalty between 0 and 2 to reduce endless repetitions"; may cause some language mixing). Applied that plus `n-predict = 2048` in the preset, and `max_tokens = 1024`, `timeout_secs = 90` on the ZeroClaw provider. Needs a re-run of the layer-4 tool-calling test because the sampler changed.
- Live test after the final switch: English and Swedish messages answered in the right language; first reply about 2 s, later replies almost instant (one llama request per message, prefix cache warm).
- Phase 2 checks passed: reminder via `cron_add` works with `deferred_builtin_tools`; a fact told to the bot was recalled after a service restart and after `/new`, so long-term memory works (the `Memory: none` startup banner is misleading). Debug logging (`RUST_LOG`, `log_llm_request_payload = "full"`) is still on and marked TODO in `zeroclaw.nix`.
- To check after the next switch: whether memory is actually off (look for `agents/assistant/workspace/memory/brain.db`), and whether `cron_add` still exists (it may be affected by `deferred_builtin_tools`).

## Schema facts verified against v0.9.0 source (2026-11-22)

Source: `docs/book/src/providers/{custom,routing}.md`, `tools/mcp.md`, `crates/zeroclaw-config/src/schema.rs` at tag v0.9.0.

- Local server provider: `[providers.models.llamacpp.<alias>]` (or `custom`), fields `uri` (FULL endpoint incl. `/v1`), `model`, `api_key`, `timeout_secs`, `temperature`, `max_tokens`, `wire_api` (defaults to chat completions), `provider_extra` (JSON merged into the request body, e.g. `chat_template_kwargs`), `fallback`, `fallback_models`. Agent references it as `model_provider = "llamacpp.<alias>"`. Warmup is `GET {uri}/models`.
- No fallback is configured unless `fallback` is set, so local-only is the default. There is also `effort_routing` (local/cloud per turn) where a local decision is restricted to the local provider. Not needed now, but a possible later way to add an opt-in cloud path.
- Thinking: the llama-server preset already has `reasoning = off`. As a belt and braces option, `provider_extra = { chat_template_kwargs = { enable_thinking = false } }` on the provider alias.
- MCP: stdio, http and sse transports. `[[mcp.servers]]` entries with `name`, `transport`, `url`, `headers` (secret, supports `$VAR` via the module's envsubst), `command`, `args`, `env`, `tool_timeout_secs` (max 600). Agents connect only to servers granted by `mcp_bundles`. So the work-hours parser can be a stdio MCP server run by ZeroClaw (give `command` a nix store path), and no script-tool mechanism is needed.
- Transcription: `[providers.transcription.local_whisper.<alias>]` with `uri` (e.g. `http://127.0.0.1:8080/inference`), optional `bearer_token`, `language`, `max_audio_bytes`, `timeout_secs`. Agent field `transcription_provider = "local_whisper.<alias>"`. The `language` hint is passed through, so it may not need to be fixed server side (to verify).
- TTS: agents also have `tts_provider = "<type>.<alias>"` (Piper is a documented provider, to check for Phase 4b).
- Telegram channel: `bot_token`, `enabled`, `stream_mode`, `mention_only`, `interrupt_on_new_message`, unauthorized-sender notice text. Authorization stays in `peer_groups`.
- Still unverified: how the module renders `settings` lists (`mcp.servers` as a Nix list of attrsets), the workspace path layout, and the exact `peer_groups` shape (taken from earlier notes).

## desktob reachability from hyllan (2026-11-22)

From hyllan (`ssh agent@hyllan.antob.net`): `http://10.64.1.6:8080/v1/models` returns 401 without a key and with a wrong key. `/health` returns 200 without a key (llama-server exempts it). `desktob.lan:8080` times out, so the LAN is blocked by the firewall as intended and only wg0 reaches the port.

## Open items

Resolved (2026-11-22): Telegram user id and bot (`@antob_home_bot`), HA MCP URL and tool names (14 tools left after `excluded_tools`), the `transcription_provider` shape (`providers.transcription.local_whisper.<alias>` plus `agents.assistant.transcription_provider = "local_whisper.<alias>"`), and the workspace path (`${dataDir}/agents/assistant/workspace`, with `IDENTITY.md`, `SOUL.md` and `USER.md` bind-mounted read-only from Nix).

Open:

- The local `api.py` patch in the HA `zeroclaw_conversation` component is overwritten by a Marketplace update. Re-apply it (see the English-only section) or skip updates, or send it upstream.
- KB-Whisper large and small were tuned for Swedish. English recognition has not been compared against `large-v3-turbo`.
- Telegram voice replies are disabled (2026-11-27), see "Telegram voice replies". Re-enable with `tts.enabled = true`.
- Phase 5 remainder: wake word and a satellite device (ESPHome or the HA companion app) for hands-free Assist.
- Backlog from "Later ideas": GLaDOS-style voice, morning brief cron job, web search through an MCP server (searxng).
