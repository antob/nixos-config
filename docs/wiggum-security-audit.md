# wiggum security audit (2026-11-20)

Live inspection over `ssh wiggum.antob.net` (read-only, `sudo -n` for logs/nft/fail2ban) plus repo review.

## State

- Hetzner VPS, `46.62.214.26` / `2a01:4f9:c013:a14a::/64`. NixOS 26.11, nixpkgs `e72e4f2` (2026-08-04), kernel 7.1.6, uptime 101 days, last switch 2026-08-11.
- Running: caddy (no sites, only admin API on 127.0.0.1:2019), fail2ban, sshd (bound to 10.64.1.5 only), wg-quick, resolved, standard systemd units.
- WireGuard: one peer (hyllan, `wg.antob.se:51820`). wiggum dials out; its listen port (57963, random) is not open in the firewall. It is a leaf behind hyllan, not an inbound entrypoint.
- headscale, tailscale, mailserver, yopass aspects are no longer imported, but their data remains.

## Intrusion check: no evidence of compromise

- sshd journal: only accepted publickey logins for `tob` with RSA `SHA256:1+kAbJ...` from 10.0.0.1 (old tunnel, Aug 7) and 10.64.1.2. No failed or invalid-user attempts.
- wtmp (since 2025-09-26): same sources only.
- sudo log: only own admin commands (Aug 7 to 11 wg/sshd recovery, matches zsh history).
- No unexpected processes, listeners, or established connections. No cron, no non-store systemd units, `/etc` only symlinks except `authorized_keys.d/tob`.
- No SUID/SGID outside `/run/wrappers`. No recent unexpected files. Kernel not tainted.
- `nix-store --verify --check-contents`: clean.
- Old caddy logs (hs.antob.se, mail.antob.se): only headscale protocol endpoints (`/ts2021`, `/key`) and ACME/redirects. Earlier fail2ban bans were Azure scanners (74.248.x) and once the home IP 195.198.148.47.

## Findings

| # | Severity | Finding |
|---|----------|---------|
| 1 | High | WireGuard private key in plaintext: `~/priv_key` (0644) and zsh history line 678 (`priv_key=...`). It is the live wg0 key. |
| 2 | Medium | Leftover data from removed services: `/var/vmail` 5.1G mail, `/var/lib/dovecot` 388M, rspamd/redis, `/var/lib/headscale` (db + noise key), `/var/lib/tailscale` state, `/var/lib/containers`, `/var/lib/docker`, 3.6G `/var/log` incl. caddy access logs with client IPs. Mail now goes to Proton (MX). |
| 3 | Medium | Dangling DNS: `hs`, `secrets`, `mail` (A + AAAA `2a01:4f9:c013:a14a::`) `.antob.se` still point to wiggum. Subdomain takeover if the IP is ever released. |
| 4 | Medium | Firewall opens 22/2222 on all interfaces. `services.openssh.openFirewall` defaults to true and adds global rules on top of the per-interface ones from `antob.openssh.interfaces`. Harmless today only because sshd binds 10.64.1.5. 80/443 are open with nothing listening. |
| 5 | Medium | `KbdInteractiveAuthentication yes` (NixOS default): PAM password login over SSH works despite `PasswordAuthentication no`. |
| 6 | Medium | The repo is public on GitHub, so the `tob` SHA-512 crypt hash in `modules/base/user/default.nix` is public and shared by all hosts. On wiggum it guards the Hetzner console login. |
| 7 | Medium | No updates for 3.5 months, no reboot for 101 days. hyllan already builds wiggum nightly. |
| 8 | Low | `ip_forward` v4/v6 enabled (leftover from tailscale exit node), no nft forward chain, so forwarding is unfiltered. |
| 9 | Low | resolved LLMNR (5355) and mDNS (5353) listen on the public interface (dropped by firewall). |
| 10 | Low | fail2ban: dovecot/postfix/caddy jails for removed services; `caddy-access` used `iptables-allports`, which failed (`iptables: command not found`). sshd jail never sees anything public. |
| 11 | Low | `~/.config/github-copilot/auth.db` (OAuth token, 0644), `~/headscale-config.yaml`, `~/acl-policy.json` left in home. |
| 12 | Low | `net.ipv6.conf.all.accept_redirects = 1`; `AllowAgentForwarding yes`; journal 3.4G with no cap. |

## Progress (2026-11-21)

Done on the host:
- Deleted `/var/vmail`, `/var/lib/{dovecot,rspamd,redis-rspamd,postfix,headscale,tailscale,containers,docker,knot-resolver,dnsmasq,wgautomesh,NetworkManager}`, `/var/lib/private/wgautomesh`, `/var/certs`, `/var/log/caddy/*`.
- Deleted `~/priv_key`, `~/headscale-config.yaml`, `~/acl-policy.json`, `~/.config/github-copilot`, and the `pub_key=`/`priv_key=`/`peer_pub_key=` lines from zsh history.

In the repo (not yet deployed):
- `openssh` aspect: `openFirewall = false` (the aspect manages the rules), `KbdInteractiveAuthentication = false`. All hosts.
- wiggum: caddy and fail2ban moved to standalone aspects `wiggum-caddy` and `wiggum-fail2ban` (not imported; mailserver/headscale/yopass import them). Forwarding sysctls removed, IPv6 redirects off, LLMNR and mDNS off.
- Note: `wiggum-mailserver` was already unbuildable (simple-nixos-mailserver module is not imported). Its fail2ban `caddy-access` jail still uses the broken `iptables-allports` action.

After deploying wiggum: delete `/var/lib/caddy`, `/var/lib/fail2ban`, `/var/log/fail2ban`.

Pending: key rotation (part of hub phase 1), DNS records (user), password to sops.

## Recommendations

1. Rotate the wg0 key: new key into sops `wg0_private_key`, update the wiggum peer pubkey on hyllan, delete `~/priv_key` and history lines 677 to 681.
2. Back up anything needed from `/var/vmail`, then remove the leftover state in finding 2 and old caddy logs. Remove the `wiggum-mailserver`, `wiggum-headscale`, `wiggum-yopass` aspects if they will not return.
3. Delete or repoint the `hs`, `secrets`, `mail` DNS records.
4. In the `openssh` aspect: `services.openssh.openFirewall = cfg.interfaces == [ ];` and `settings.KbdInteractiveAuthentication = false;` (all hosts benefit).
5. On wiggum: drop the 80/443 rule and caddy entirely if no sites remain; then fail2ban can go too (or keep only sshd). wiggum needs no inbound public ports.
6. Drop the forwarding sysctls in `modules/hosts/wiggum/default.nix`; set `net.ipv6.conf.all.accept_redirects = 0`.
7. Disable LLMNR and mDNS in resolved (`LLMNR=no`, `MulticastDNS=no`).
8. Move the user password to a sops `hashedPasswordFile` (yescrypt, new strong password), since the current hash is public.
9. Update regularly: `just deploy switch wiggum` from the nightly cache build, plus reboots for kernels, or `system.autoUpgrade` with `allowReboot`.
10. Optional: Hetzner Cloud Firewall with no inbound rules as an outer layer; `services.journald.extraConfig = "SystemMaxUse=500M"`; `AllowAgentForwarding no`.
