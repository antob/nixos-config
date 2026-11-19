# hyllan skill: review and plan

Status: proposal reviewed, nothing implemented. Written 2026-11-19.

## Proposal under review

1. A `hyllan` skill in `.agents/skills/hyllan/SKILL.md`, modelled on the `home-assistant` skill: services, containers, log commands, conventions (restricted `agent` user, `agent-access` aspect, read-only by default).
2. A `just ssh-diag hyllan <unit>` recipe that batches status and recent logs into one SSH call.

## Findings

### What agents ran against hyllan

Source: Bash tool calls containing `hyllan` in 310 Pi session files (`~/.pi/agent/sessions/--home-tob-Projects-nixos-config--/`, nested subagent files included) and the Claude Code JSONL (`~/.config/claude/projects/-home-tob-Projects-nixos-config/`). Period 2026-07-20 to 2026-11-19. Counted with a throwaway script (regex `ssh\b[^|;]*hyllan` on the command string, deduplicated on command plus timestamp). The earlier figure of about 530 used a different count; this one is 909.

| Metric | Count |
|---|---|
| Bash calls mentioning `hyllan` | 1443 (Pi 956, Claude 487) |
| SSH calls to hyllan | 909 (Pi 674, Claude 235), in 40 sessions |
| of which as `agent@hyllan.antob.net` | 41 (all since 2026-11-18, when `agent-access` landed) |
| SSH calls using `sudo` on the remote | 465 (51%) |
| SSH calls already batching several commands (`;` or `&&`) | 710 (78%) |
| SSH calls that changed state (restart, rm, mv, chmod, zfs set, ...) | about 170 |
| Calls reading `/run/secrets` or using `sops` | 33 |

Concentration: 8 sessions account for 690 of the 909 calls (76%). They were one-off investigations: ESPHome devices (132), HA overhaul (123), Music Assistant container (112), btrfs-to-ext4 migration (85), NFS (67 + 58), binary cache speed (62), DNS queries from hyllan (48). Since `agent-access` exists, 39 of 41 hyllan SSH calls went through the agent user.

Command families inside SSH calls (one call can match several):

| Pattern | Calls |
|---|---|
| `cat` / `ls` / `grep` / `find` on files | 267 / 257 / 481 / 57 |
| `readlink`, `/run/current-system`, store paths | 201 |
| ESPHome (CLI, dashboard, YAML) | 150 |
| `journalctl` | 139 |
| `podman` (exec 44, ps 17, logs 15, inspect 8) | 100 |
| `zfs` / `zpool` | 93 |
| `systemctl is-active/show/list-*/cat` | 86 |
| `curl` | 81 |
| `free`, `uptime`, `top`, `ps` | 66 |
| `ss`, `ip`, `nft` | 44 |
| `restic` | 34 |
| `systemctl status` | 25 |
| `mysql` / `sqlite3` / `psql` | 10 / 9 / 1 |

Most targeted units (any `systemctl`/`journalctl` use): `esphome` 45, `nix-cache-build` 32, `podman-hass` 27, `nix-serve` 26 (stale name, the cache now runs `harmonia`), `caddy` 19, `zigbee2mqtt` 12, `nfs-server` 12, `restic-rest-server` 11, `searx` 11, `photoprism` 8, `greenely-statistics` 8, `podman-languard-*` 11, `syncthing` 5, `systemd-networkd` 5.

`journalctl -u` targets: `nix-cache-build` 29, `caddy` 10, `restic-rest-server` 10, `podman-hass` 9, `nix-serve` 7, `esphome` 7, `searx` 6, `zigbee2mqtt` 6, `podman-languard-*` 10, others 1 or 2 each.

Containers in `podman logs/exec/inspect`: `hass` 61, `mass` 13, `ytdlp-pot-provider` 2.

Paths: `/mnt/tank/services/hass` 123, `/mnt/tank/services/esphome` 81, `/mnt/tank/share/private` 69, `/mnt/tank/services/nix-cache` 33, `/var/lib/photoprism` 68, `/var/lib/containers/storage` 22, `/run/secrets/*` 27, `/var/lib/bitwarden_rs/db.sqlite3` 10.

About 35% of historical traffic (HA, ESPHome, zigbee2mqtt) is already covered by the `home-assistant` skill. The rest is spread over a long tail of services with no repeat pattern except the nix cache build, caddy and restic.

### What is deployed (from config, `nix eval`)

Systemd services of interest: `caddy`, `harmonia`, `nix-cache-build` (timer 03:00), `restic-rest-server`, `restic-prune-all-client-backups` (02:30), `restic-backups-{hass,mysql,photoprism,postgresql,private_share,public_share,restic-server,syncthing,tank}` (01:05), `photoprism`, `mysql`, `postgresql`, `searx`, `syncthing`, `vaultwarden`, `copyparty`, `beszel-hub`, `beszel-agent`, `freshrss-*`, `atuin`, `nfs-server`, `samba-{smbd,nmbd,wsdd,winbindd}`, `smartd`, `zfs-{import-zpool,mount,share,scrub,zed}`, `mosquitto`, `zigbee2mqtt`, `esphome`, `greenely-statistics`, `notify-failure@`, `podman-prune`.

Containers (`virtualisation.oci-containers`, rootful podman): `hass`, `mass`, `ytdlp-pot-provider`, `languard-backend`, `languard-frontend`, `languard-scanner`. Unit names are `podman-<name>`.

Not imported (standalone aspects): `hyllan-nginx`, `hyllan-open-webui`, `hyllan-plex`.

### What the `agent` user may do

From `modules/services/agent-access.nix` and the `antob.agent-access` blocks in `modules/hosts/hyllan/{homeassistant,esphome,greenely-statistics}.nix` (evaluated):

- Login: key in `modules/services/_files/agent-ssh-key.pub`, `restrict` (no pty or forwarding), only from `10.64.1.0/24` (WireGuard). System user, groups: only `agent`. No `wheel`, no `systemd-journal`.
- Start/stop/restart (polkit): `podman-hass`, `zigbee2mqtt`, `greenely-statistics`, `esphome`.
- Logs via `sudo agent-logs`: `podman-hass`, `zigbee2mqtt`, `mosquitto`, `caddy`, `greenely-statistics`, `esphome`.
- Root commands via sudo: `agent-logs`, `hass-ctl` (`ps|inspect|stats|top|images|check-config` on `hass`).
- Run anything as `esphome : dialout`.
- Extra packages: `bind` (dig), `esphome-cli`, `git`. Git safe dir: the HA config dir.

Verified live with two read-only calls as `agent` (2026-11-19): `systemctl is-active`, `systemctl status` (without log lines), `systemctl --failed`, `list-timers`, `zpool status`, `df`, `readlink /run/current-system` and `ls /mnt/tank/services` work. Plain `journalctl` prints "No journal files were opened due to insufficient permissions". `podman ps` fails (rootless, no subuid). `/run/secrets` is denied.

So for the units agents read most outside HA (`nix-cache-build`, `harmonia`, `restic-*`, `searx`, `photoprism`, `podman-mass`, `podman-languard-*`, `nfs-server`) the agent user can see status but not logs, and cannot touch containers other than `hass`.

## Review verdict

The skill is worth doing, but small: the useful content is the unit and container name map, the agent user's actual rights and a fallback rule, and it should hand HA and ESPHome off to the existing skill. The `just ssh-diag` recipe is not worth doing: through the agent user there is no touch to save, agents already batch 78% of their SSH calls, and a justfile recipe can neither widen the agent's rights nor be called usefully as the user without a touch. The real gap is rights, not tooling: the agent user can read logs of only 6 units, so most non-HA diagnosis would still fall back to `ssh hyllan.lan`. The highest value change is extending `logUnits` per service on hyllan, which is a Nix change the user builds.

Details:

- **Worth doing**: short skill (target under 2.5 KB); `logUnits` grants for the read-mostly services; one line in `AGENTS.md` pointing remote diagnosis at the agent user.
- **Not worth doing**: `just ssh-diag`. A combined status-plus-logs call is one line of skill text: `ssh agent@hyllan.antob.net 'systemctl status <u> --no-pager -n0; sudo agent-logs <u> -n 100'`. If a helper is wanted anyway, it belongs on hyllan inside `agent-access` (next to `agent-logs.py` in `modules/services/_files/`), not in `justfile` and not in `modules/shell/scripts/_files/` (those are user-facing workstation commands).
- **Missing from the proposal**:
  - A fallback rule: when the agent user lacks a right, say which grant is missing and either print the command for the user or ask before `ssh hyllan.lan` (touch). Do not silently switch to the user account.
  - Guardrails for the 33 secrets lookups and about 170 state-changing calls seen historically: never read `/run/secrets` or sops-decrypted files; state changes only on request.
  - Staleness: agents used `nix-serve` 26 times after it became `harmonia`. A hardcoded inventory goes stale the same way. The skill should list only names that are not obvious from the file name, and tell the agent to check `modules/hosts/hyllan/<service>.nix` or `nix eval` for the rest.
  - Container access beyond `hass`: `mass` was the second most inspected container. A generic allow-listed container helper would cover it, but see risks on `inspect`.
- **AGENTS.md vs skill**: the rule "use `ssh agent@<host>.antob.net` for read-only diagnosis, ask before `ssh <host>.lan`" applies to every host that imports `agent-access`, so it belongs in `AGENTS.md` (one or two lines, the "Working With the User" section already mentions the agent user). The hyllan unit and path map belongs in the skill, loaded only when needed.

## Phase plan

### Phase 1: skill text only (no Nix, no justfile)

1. Write `.agents/skills/hyllan/SKILL.md` from the outline below. Keep it under about 60 lines.
2. Propose (not apply) a one or two line addition to `AGENTS.md` "Working With the User": prefer `ssh agent@<host>.antob.net` for read-only checks on hosts with `agent-access`, see the host skill for its rights, ask before `ssh <host>.lan`.
3. User reviews both.

### Phase 2: widen read-only grants on hyllan (Nix, user builds and switches hyllan)

1. Add `antob.agent-access.logUnits` in each service file, next to the service, as `homeassistant.nix` does. Proposed: `nix-cache-build`, `harmonia` (`nix-cache.nix`); `restic-rest-server`, `restic-prune-all-client-backups` (`restic-server.nix`); every `restic-backups-*` (`backup.nix`, derived from `attrNames config.services.restic.backups`); `searx`; `photoprism`; `syncthing`; `vaultwarden`; `copyparty`; `nfs-server`; `samba-smbd`; `podman-mass`, `podman-ytdlp-pot-provider`; `podman-languard-{backend,frontend,scanner}`; `systemd-networkd`; `zfs-zed`, `zfs-mount`, `zfs-import-zpool`; `smartd`.
2. Update the skill's rights table.
3. Optionally add `nix-cache-build` to `units` so the agent can re-run the nightly build (ask the user; it is heavy).

### Phase 3 (optional): container read helper

Generalise `hass-ctl` into an `agent-podman` command in `agent-access` with an option `antob.agent-access.containers` (allow-list) and fixed subcommands `ps`, `stats`, `top`, `images`, plus a filtered `inspect` (see risks). Container logs are already covered by `agent-logs podman-<name>` once phase 2 grants them. `hass-ctl check-config` stays HA-specific.

### Phase 4: measure

After two to four weeks, re-run the mining (regex above) and count `ssh hyllan.lan` calls versus `agent@` calls, plus which missing grants caused fallbacks.

## Draft outline of SKILL.md

```
---
name: hyllan
description: Diagnose services on the home server hyllan (caddy, nix binary cache and nightly
  cache build, restic server and backups, NFS, samba, photoprism, syncthing, searxng,
  vaultwarden, copyparty, music assistant, lan-guard, ZFS). Not Home Assistant, ESPHome or
  zigbee2mqtt: use the home-assistant skill for those.
---

# hyllan

## Access
- `ssh agent@hyllan.antob.net '<cmd>'` (WireGuard, no touch, no tty). Batch commands in one call.
- `ssh hyllan.lan` needs a YubiKey touch: only when the agent user lacks the right, after asking.
  Say which `antob.agent-access` grant would avoid it.
- Read-only unless the user asks for a change. Never read /run/secrets or decrypt sops files.

## What the agent user can do
(table: action -> command; status/is-active/--failed/list-timers unprivileged; logs via
`sudo agent-logs <unit> -n N -S since -g regex -o cat`; restart list; zpool/df/readlink work;
no journalctl, no podman, no sudo otherwise). Grants live in modules/services/agent-access.nix
and `antob.agent-access` blocks in modules/hosts/hyllan/*.nix. `sudo agent-logs` without
arguments lists allowed units.

## One-call diagnosis
ssh agent@hyllan.antob.net 'systemctl status <u> --no-pager -n0; sudo agent-logs <u> -n 100 -o cat'

## Name map (only the non-obvious ones)
- binary cache: harmonia (not nix-serve), nightly build nix-cache-build (03:00), data /mnt/tank/services/nix-cache
- backups: restic-backups-<name> (01:05), server restic-rest-server, prune 02:30
- containers are rootful podman, unit podman-<name>: hass, mass, ytdlp-pot-provider, languard-*
- searxng unit is `searx`; vaultwarden data /var/lib/bitwarden_rs
- service data under /mnt/tank/services/<service>, shares /mnt/tank/share/{private,public}
- Anything else: read modules/hosts/hyllan/<service>.nix

## Deployed version
readlink /run/current-system vs `just store-result`; nightly cache build uses pushed main only.

## Changes
Nix changes: say "build and switch hyllan" and stop. Restarts only for units in the restart list,
and only when asked.
```

## Recipe or script design

Recommendation: no `justfile` recipe and no workstation script.

If the user still wants a single command, the right shape is a remote-side mode on the existing helper, not a local wrapper:

- `sudo agent-logs --status <unit>…`: for each allowed unit, print `systemctl show -p ActiveState,SubState,Result,ExecMainStatus,ActiveEnterTimestamp`, the matching timer's last and next run if one exists, then the last N journal lines. Same allow-list as logs. Lives in `modules/services/_files/agent-logs.py`; no new sudo rule.
- Cost: about 20 lines of Python. Benefit over the one-liner: marginal (fewer tokens of command text). Only worth it if phase 4 shows agents still running several round trips per diagnosis.

## Risks

- **Secrets in logs**: widening `logUnits` exposes those journals to anything holding the agent key (stored as a sops secret on workstations). Restic, caddy (ACME) and nix-cache-build logs are normally clean; check vaultwarden and photoprism logs for tokens before granting.
- **`podman inspect` leaks env**: `Config.Env` holds environment variables, including values from `--env-file`. The existing `hass-ctl inspect` already has this exposure; a generic helper should drop `Env` (for example `--format` with selected fields).
- **Stale skill**: inventory drifts from config (see `nix-serve`). Mitigated by listing only non-obvious names and pointing at the Nix files.
- **Gitignored skill**: `.agents/skills/` is not tracked, so the skill has no history or backup unless the user keeps it elsewhere.
- **Skill not triggering**: hyllan tasks often start as "caddy can't renew certs" without saying hyllan. The description lists service names for that reason.
- **Token cost**: each extra table row is paid on every load. Keep the skill short and leave history and incident notes out.

## Open questions for the user

1. Which of the phase 2 log grants are acceptable? Any service whose logs you consider sensitive (vaultwarden, photoprism, syncthing)?
2. Should the agent be allowed to start `nix-cache-build` or restart other units (caddy, searx, restic-rest-server), or stay log-only outside HA?
3. Do you want a generic container helper (phase 3), and should `hass-ctl inspect` be changed to drop `Env`?
4. Is the `AGENTS.md` pointer rule wanted, or should everything stay inside the skill?
5. The skill folder is gitignored. Fine to keep the hyllan skill untracked like `home-assistant`?
