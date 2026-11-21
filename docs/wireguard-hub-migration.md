# WireGuard hub migration: hyllan to wiggum

Goal: wiggum (public VPS) becomes the wg0 hub so the network no longer depends on the home IP and router port forward. Subnet and addresses stay the same (`10.64.1.0/24`).

## Current state

- hyllan `10.64.1.2` is the hub: systemd-networkd wg0, `ListenPort 51820`, `IPMasquerade = ipv4` (so spokes see forwarded traffic as `10.64.1.2`), one `/32` peer per node (`modules/hosts/hyllan/wireguard.nix`).
- Spokes use the shared `wireguard` aspect (`modules/network/wireguard.nix`): wg-quick, single peer hyllan, `endpoint = wg.antob.se:51820`, `AllowedIPs = 10.64.1.0/24`.
- Nodes: pikvm `.3`, pihole `.4` (DNS), wiggum `.5`, desktob `.6`, laptob `.7`, iPhone `.8` (`gen-wg-conf` on hyllan), pidesk `.9`.

## Principles

- WireGuard picks the peer by longest-prefix match on AllowedIPs, for outgoing routing and for validating incoming source IPs. Two hubs can therefore coexist: each holds `/24` towards the other hub plus `/32` for the spokes it serves directly.
- Each spoke moves on its own. Only that spoke has a short gap (seconds, between two deploys). The rest of the network keeps working.
- No node may be left without a management path. wiggum is the only node reachable *only* over wg0, so it gets a temporary public SSH path first.

## Phase 1: safety net and wiggum key rotation

1. wiggum: temporary SSH on the public interface, home IP only: sshd also listens on `46.62.214.26`, nft rule `iifname "enp1s0" ip saddr 195.198.148.47 tcp dport 22 accept`. Confirm the Hetzner web console login works as a last resort (needs the `tob` password).
2. New wg0 key for wiggum into sops (`wg0_private_key`). Update wiggum's peer pubkey on hyllan.
3. Deploy wiggum (over the public SSH path), then hyllan. Only the hyllan to wiggum link is down in between. Verify the handshake.
4. Delete `~/priv_key` and the `priv_key=` line from zsh history on wiggum.

## Phase 2: wiggum hub-capable, no spoke changes

1. Refactor the `wireguard` aspect: one node table (name, IP, pubkey), option `antob.wireguard.hub` (`hyllan` or `wiggum`, default `hyllan` during migration) that selects the spoke's peer block, and a hub mode that generates peers from the table.
2. wiggum: `listenPort = 51820`, open UDP 51820 on enp1s0, IPv4 forwarding with an nft forward chain (`iifname wg0 oifname wg0 accept`, policy drop), IPv6 forwarding off, no masquerade. Peers: hyllan only, still `10.64.1.0/24`, endpoint `wg.antob.se:51820`.
3. hyllan: widen the wiggum peer to `AllowedIPs = 10.64.1.0/24`. The direct `/32` spoke peers still win.
4. DNS: new record `hub.antob.se` A `46.62.214.26` (a dedicated name so the hub can move again without touching clients).
5. Verify: from wiggum, ping every node (still via hyllan).

## Phase 3: move spokes one at a time

Order: laptob, desktob, pidesk, pikvm, pihole, iPhone. Home hosts keep LAN SSH as a fallback.

Per spoke X:

1. wiggum: add peer X `/32`. Deploy wiggum. Harmless: only wiggum to X breaks until step 2.
2. X: `antob.wireguard.hub = "wiggum"` (endpoint `hub.antob.se:51820`). Deploy X.
3. hyllan: remove X's direct peer. Deploy hyllan right after step 2. Between 2 and 3, X cannot reach hyllan or the unmigrated spokes.
4. Verify: handshake for X on wiggum, ping X from hyllan and from another spoke.

iPhone: point `gen-wg-conf` at the wiggum pubkey and `hub.antob.se`, regenerate the QR code, re-import.

## Phase 4: hyllan becomes a spoke

1. hyllan: single peer wiggum, `AllowedIPs = 10.64.1.0/24`, endpoint `hub.antob.se:51820`, keepalive 25. Remove `ListenPort`, the UDP 51820 firewall rule and `IPMasquerade`. Deploy hyllan (it now initiates; wiggum still has the old endpoint, so both directions work).
2. wiggum: hyllan peer to `10.64.1.2/32`, no endpoint. Deploy wiggum.
3. Remove the router port forward for UDP 51820. Remove or repoint `wg.antob.se`.
4. Remove the temporary public SSH path on wiggum.

## Phase 5: cleanup

Drop the migration scaffolding (`hub` option default becomes `wiggum` or the option goes away) and finish the remaining audit items for wiggum (caddy removal, fail2ban).

## Decision: hairpin traffic (chosen: B)

With a pure hub, home hosts reach hyllan via Helsinki (home upload, then download). This affects NFS and restic from desktob and laptob, and DNS to pihole.

- A: pure hub. Simple. All traffic hairpins.
- B: hub plus direct links from stationary home hosts to hyllan (spoke: hyllan peer `10.64.1.2/32` with LAN endpoint; hyllan: spoke peer `/32` next to wiggum `/24`). Bulk traffic stays local, no port forward needed. laptob and iPhone roam, so they stay on the pure hub.

Status: option B chosen (2026-11-21). Not started. Phase 1 key rotation still pending; `~/priv_key` and the history lines are already deleted.
