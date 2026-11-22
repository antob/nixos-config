# ZeroClaw personal assistant on hyllan

Status (2026-11-22): Phases 1 and 2 done, Phase 3 working. Sources: ZeroClaw docs, schema and `nix/module.nix` at tag `v0.9.0`; OpenRouter models API; HA `mcp_server` and `llm` docs.

## Handoff state (2026-11-22)

Running and verified by the user: Telegram bot `@antob_home_bot` -> ZeroClaw 0.9.0 on hyllan -> llama-server (preset `zeroclaw`, Qwen3.6-35B-A3B) on desktob over wg0. Language rule (Swedish default, English when addressed in English), reminders (`cron_add`), long-term memory, HA lights by device, area and floor all work. Both hosts were switched after the sampler/cap change and the `SOUL.md` "Home" section.

Done and switched (2026-11-22): `auto_approve` for GetLiveContext, GetDateTime, HassTurnOn, HassTurnOff (volume still asks); `excluded_tools` for 6 unused HA tools (15 HA tools left); custom chat template on desktob that fixes reply language and emojis (see "Reply language investigation"). Verified in Telegram after `/new`: Swedish, Swedish, English, Swedish commands each answered in the right language, no emojis, lights switched.

Done earlier: `risk_profiles.assistant.auto_approve` (GetLiveContext, GetDateTime, HassTurnOn, HassTurnOff) in `modules/hosts/hyllan/zeroclaw.nix`. Reason: the Telegram "Always" button does not persist, so every call asked for approval. Checked 2026-11-22: `nix eval` shows the four names; the running unit (started 16:07, config `4522hzmw...-zeroclaw-assistant-config.toml`) has no `auto_approve`, so hyllan is not switched yet. The HA tool names are not in the trace or the journal (MCP tools are deferred), so step 2 needs a fresh `tools/list` from HA.

Nothing is committed. Changed or new files: `flake.nix`, `flake.lock` (only the `zeroclaw` input), `modules/ai/llama-cpp.nix`, `modules/ai/_files/zeroclaw-qwen3.6.jinja` (new, `git add -N`), `modules/hosts/desktob/default.nix`, `modules/hosts/hyllan/{backup.nix,secrets.yaml,zeroclaw.nix}`, `modules/hosts/hyllan/_files/zeroclaw/{IDENTITY.md,SOUL.md}`, `modules/hosts/desktob/secrets.yaml` (check `git status`), and this doc (untracked). Commit only when the user asks.

Done 2026-11-22, not yet switched: debug settings removed from `zeroclaw.nix` (`RUST_LOG`, `observability.log_llm_request_payload`); hyllan needs a switch. Local test data in `/tmp` deleted. The trace on hyllan still holds full prompts until its 200-event window rolls over.

Done 2026-11-22 in HA (entity registry, backup in `/tmp/registries-2026-11-22`): Swedish aliases (indefinite and definite form) on all 12 exposed lights, e.g. Taklampa/Taklampan, TV-lampa/TV-lampan, Julgran/Julgranen, Fönsterlampa, Fönsterbelysning, Entrélampa, Ljusslinga, Altanlampa, Kvällsbelysning, Utebelysning. Note: the earlier "taklampan" failure was HA's "No entities matched the device class" with name `ceiling light`, so aliases may not be the whole fix. Seen while listing: `switch.upstairs_closet_hyllan` (the plug that powers hyllan) is exposed to Assist; it was disabled so not a tool. Un-exposed on 2026-11-22 at the user's request; it no longer appears in the exposed-entities list.

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

- Telegram user id and bot name (Phase 1).
- Exact HA MCP URL path and Device control tool names (after Phase 1 / first connect).
- `transcription_provider` field name on agents and the `[providers.transcription.local_whisper.<alias>]` vs `[transcription.local_whisper]` shape (docs show both; verify against `zeroclaw config schema` on the built binary).
- Workspace path (module env vs docs layout).
