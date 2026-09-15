#!/usr/bin/env bash
# Pull the PiKVM-patched RPi kernel outputs from aostanin's cache for the given host.
#
# We deliberately don't add aostanin.cachix.org to modules/nix/default.nix's
# substituters: Nix trusts a substituter's key for *any* store path it's asked
# about, not just the packages its maintainer intends to publish, so adding it
# system-wide would let it substitute unrelated packages too. This fetches only
# the exact kernel output paths instead, with the extra cache scoped to this one
# invocation via --option (never written to nix.conf).
#
# Usage: fetch-pikvm-kernel.sh [--store PATH] [HOST]
# Run from the repo root (or pass a $work checkout as cwd) after bumping the
# `kvmd` flake input, before building HOST (default: pikvm).
set -euo pipefail

store_args=()
host="pikvm"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --store)
      store_args=(--store "$2")
      shift 2
      ;;
    *)
      host="$1"
      shift
      ;;
  esac
done

cache="https://aostanin.cachix.org"
key="aostanin.cachix.org-1:loDfTVc4XTxROFAPv3NKNfKzLCKEzAGj8aPKJFbRs5Q="

# aostanin's cache doesn't host the kernel's build-time closure (gcc, perl, ...),
# only the final outputs, so the machine's already-trusted substituters need to be
# listed alongside it for `nix build` to assemble the rest. Read them from the
# ambient nix.conf instead of hardcoding a second copy here.
ambient_substituters=$(nix config show --json | jq -r '.substituters.value | join(" ")')
ambient_keys=$(nix config show --json | jq -r '."trusted-public-keys".value | join(" ")')
substituters="$cache $ambient_substituters"
keys="$key $ambient_keys"

for output in out dev modules; do
  path=$(nix "${store_args[@]}" eval --raw ".#nixosConfigurations.${host}.config.boot.kernelPackages.kernel.${output}")
  if nix "${store_args[@]}" path-info "$path" >/dev/null 2>&1; then
    echo "already present: $path"
  else
    echo "fetching: $path"
    nix "${store_args[@]}" build --no-link --option substituters "$substituters" --option trusted-public-keys "$keys" "$path"
  fi
done
