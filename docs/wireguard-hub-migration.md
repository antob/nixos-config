# WireGuard hub migration: hyllan to wiggum

**Status: abandoned (2026-11-21), hyllan stays the hub.** A wiggum hub decrypts all spoke to spoke traffic (NFS, restic over HTTP, DNS) on an internet-facing VPS and becomes a router into the home network, while nearly everything used lives at home. The home IP and port forward have not been a real problem. Kept from the work: wiggum key rotation, the node table, `restartUnits` and the dormant hub mode in `modules/network/wireguard.nix`. See "Rollback" at the end.

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

1. wiggum: temporary SSH on the public interface, home IP only: sshd listens on all addresses (instead of binding `46.62.214.26`, so it does not depend on enp1s0 DHCP timing), nft rule `iifname "enp1s0" ip saddr 195.198.148.47 tcp dport 22 accept`; the firewall still only opens 22/2222 on wg0 otherwise. Confirm the Hetzner web console login works as a last resort (needs the `tob` password).
2. New wg0 key for wiggum into sops (`wg0_private_key`). Update wiggum's peer pubkey on hyllan.
3. Deploy wiggum (over the public SSH path), then hyllan. Only the hyllan to wiggum link is down in between. Verify the handshake.
4. Delete `~/priv_key` and the `priv_key=` line from zsh history on wiggum.

## Phase 2: wiggum hub-capable, no spoke changes

1. Refactor the `wireguard` aspect: one node table (name, IP, pubkey, `home` flag for the stationary hosts that keep a direct link to hyllan), a `wiggumSpokes` list in the aspect that selects each spoke's peer block (a list rather than a per-host option, so wiggum's peers and the spoke's peers come from the same edit), and a hub mode (`antob.wireguard.hub = true`) that generates peers from the table. A listed `home` spoke gets two peers: wiggum `10.64.1.0/24` (endpoint `hs.antob.se:51820`, keepalive 25) and hyllan `10.64.1.2/32` (endpoint `192.168.1.2:51820`, a literal IP so it does not depend on DNS).
2. wiggum: `antob.wireguard.hub = true`, which sets `listenPort = 51820`, opens UDP 51820 (globally; wiggum only has enp1s0 and wg0), IPv4 forwarding with an nft forward chain (`iifname wg0 oifname wg0 accept`, policy drop), IPv6 forwarding off, no masquerade. Peers: hyllan only, still `10.64.1.0/24`, endpoint `wg.antob.se:51820`.
3. hyllan: widen the wiggum peer to `AllowedIPs = 10.64.1.0/24`. The direct `/32` spoke peers still win.
4. DNS: none needed. During the migration the hub endpoint is `hs.antob.se`, which already resolves to `46.62.214.26`. `wg.antob.se` keeps pointing home until phase 4.
5. Verify: from wiggum, ping every node (still via hyllan).

## Phase 3: move spokes one at a time

Order: laptob, desktob, pidesk, pikvm, pihole, iPhone. Home hosts keep LAN SSH as a fallback. Home spokes (option B): desktob, pidesk, pikvm, pihole. Roaming spokes: laptob, iPhone.

Per spoke X:

1. Add X to `wiggumSpokes` in `modules/network/wireguard.nix`. This changes both wiggum (peer X `/32`) and X (peer wiggum).
2. Deploy wiggum first (harmless: only wiggum to X breaks), then X.
3. Roaming X: hyllan removes X's direct peer; deploy hyllan right after step 2. Between 2 and 3, X cannot reach hyllan or the unmigrated spokes. Home X: hyllan keeps X's `/32` peer, nothing to deploy (X now reaches hyllan directly and everything else via wiggum).
4. Verify: handshake for X on wiggum (and on hyllan for home X), ping X from hyllan and from another spoke, `ip route get` / `wg show` on X to confirm hyllan traffic uses the direct peer.

iPhone: point `gen-wg-conf` at the wiggum pubkey and `hs.antob.se`, regenerate the QR code, re-import.

## Phase 4: hyllan becomes a spoke

1. hyllan: wiggum peer `AllowedIPs = 10.64.1.0/24`, endpoint `hs.antob.se:51820`, keepalive 25, plus the `/32` peers of the home spokes (no endpoint, they initiate). Keep `ListenPort 51820` for the home spokes, but open UDP 51820 only on the LAN interface. Remove `IPMasquerade` and `IPv4Forwarding` (hyllan no longer forwards). Deploy hyllan (it now initiates; wiggum still has the old endpoint, so both directions work).
2. wiggum: hyllan peer to `10.64.1.2/32`, no endpoint. Deploy wiggum.
3. Remove the router port forward for UDP 51820. Retarget `wg.antob.se` to `46.62.214.26` (only now: before this, unmigrated spokes use it to reach hyllan).
4. Remove the temporary public SSH path on wiggum (restore `listenAddresses = [ "10.64.1.5" ]`, drop `extraInputRules`).

## Phase 5: cleanup

Switch `hubEndpoint` in the aspect (and hyllan's wiggum peer) from `hs.antob.se` to `wg.antob.se` and deploy all nodes. The iPhone config holds the resolved IP (`gen-wg-conf` resolves the name), so it needs no change. Drop the migration scaffolding (`wiggumSpokes` and `oldHubEndpoint` go away; every spoke uses wiggum) and finish the remaining audit items for wiggum (caddy removal, fail2ban).

## Decision: hairpin traffic (chosen: B)

With a pure hub, home hosts reach hyllan via Helsinki (home upload, then download). This affects NFS and restic from desktob and laptob, and DNS to pihole.

- A: pure hub. Simple. All traffic hairpins.
- B: hub plus direct links from stationary home hosts to hyllan (spoke: hyllan peer `10.64.1.2/32` with LAN endpoint; hyllan: spoke peer `/32` next to wiggum `/24`). Bulk traffic stays local, no port forward needed. laptob and iPhone roam, so they stay on the pure hub.

Status: option B chosen (2026-11-21) and folded into phases 2 to 4.

## Progress

- Phase 1.4 done: `~/priv_key` and the history lines are deleted.
- Phase 1.1 done and deployed (2026-11-21): public SSH from home and the Hetzner console both work.
- Phase 1.2 done (2026-11-21): new `wg0_private_key` in `modules/hosts/wiggum/secrets.yaml`, wiggum pubkey `kXis0LY2yJ9xmauVtbd0XvGGOFpgUU0etPHB//1JCQ0=` on hyllan.
- Phase 1.3 done (2026-11-21): hyllan shows a handshake with wiggum's new key from `46.62.214.26`. Phase 1 complete.
- Note: rotating a sops key file does not restart `wg-quick-wg0` (same path, unit unchanged); restart it by hand or set `restartUnits` on the secret.
- Phase 1 committed as 9745756.
- Phase 2.1 code done (2026-11-21, uncommitted): node table, `wiggumSpokes`, hub mode and `restartUnits` in `modules/network/wireguard.nix`; hosts no longer set `address`/`privateKeyFile` (derived from the table and `wg0_private_key`). `nix eval` of `networking.wg-quick.interfaces.wg0` is identical to before on wiggum, pikvm, pihole, pidesk, desktob and laptob; hub mode evaluates on wiggum. Deploying it changes nothing on wg0 except the new `restartUnits`.
- hyllan (networkd) and `gen-wg-conf` still hold their own copies of the pubkeys; phase 4 is the natural point to move hyllan onto the table (open question).
- Phase 2.2 and 2.3 code done (2026-11-21, uncommitted): wiggum sets `antob.wireguard.hub = true` (also `send_redirects = 0`, since spokes only reach each other through the hub); hyllan's wiggum peer is `10.64.1.0/24`. Verified with `nix eval`: wiggum has `listenPort 51820`, UDP 51820 open, forward filter on, one peer hyllan `/24` via `wg.antob.se`; hyllan peers unchanged apart from wiggum `/24`.
- Known wart until phase 4: packets to unassigned wg0 addresses loop between hyllan and wiggum until TTL expires (each holds `/24` towards the other).
- Phase 2 deployed and verified (2026-11-21): wiggum listens on 51820, handshake with hyllan, wiggum pings .2 .3 .4 .6 .7 .9, hyllan's wiggum peer shows `10.64.1.0/24`. Other hosts get the 2.1 change (`restartUnits` only) on their next deploy.
- Phase 2 committed as 76f097c.
- Phase 3 laptob code done (2026-11-21, uncommitted): `wiggumSpokes = [ "laptob" ]`, laptob peer removed on hyllan. Verified with `nix eval`: wiggum has hyllan `/24` plus laptob `/32`; laptob has a single peer wiggum `/24` via `hs.antob.se`. Deployed and verified (2026-11-21): handshake on wiggum, laptob reaches hyllan, desktob and DNS, hyllan reaches laptob.
- Open point for home spokes: option B only links them directly to hyllan, so wg0 DNS to pihole (`10.64.1.4`) from desktob and pidesk will go via wiggum. Consider `antob.wireguard.dns = "192.168.1.4"` on home hosts.
- Next: phase 3 desktob (home spoke).

## Rollback (2026-11-21)

Code (uncommitted): `wiggumSpokes = [ ]`, hyllan's wireguard config back to its phase 1 state (laptob `/32` peer restored, wiggum peer `10.64.1.5/32`), `antob.wireguard.hub` removed from wiggum. `nix eval` of wg0 on wiggum and laptob matches the pre-migration baseline; hyllan's file is identical to commit 9745756.

Deployed and verified (2026-11-21): hyllan shows handshakes for wiggum, laptob and the other spokes; wiggum and laptob checks pass.

Deploy order used: hyllan, then laptob right after (laptob is cut off from hyllan and the other spokes in between), then wiggum over `46.62.214.26` (its wg0 restarts). Verify: handshakes for laptob and wiggum on hyllan, wiggum pings every node, laptob pings hyllan and desktob.

After that: remove the temporary public SSH on wiggum (restore `listenAddresses = [ "10.64.1.5" ]`, drop `extraInputRules`), deployed over wg0. Optionally drop the unused migration scaffolding (`wiggumSpokes`, `hubEndpoint`, `hyllanLanEndpoint`, `home` flags).
