# vaultwarden-local is a local instance of vaultwarden (Bitwarden server)
# for restoring backups. It runs on localhost with a self-signed certificate.

{ pkgs, ... }:
pkgs.writeShellScriptBin "vaultwarden-local" ''
  VW_BIN="${pkgs.vaultwarden}/bin/vaultwarden"
  WEB_VAULT_FOLDER="${pkgs.vaultwarden-webvault}/share/vaultwarden/vault"

  if [ -n "$XDG_CACHE_HOME" ]; then
    CERT_DIR="$XDG_CACHE_HOME/vaultwarden-local"
  else
    CERT_DIR="$HOME/.cache/vaultwarden-local"
  fi

  usage() {
    echo "usage: vaultwarden-local <vault-dir> [port]" >&2
    exit 1
  }

  [ $# -ge 1 ] || usage
  vaultDir="$1"
  port="8080"
  [ $# -ge 2 ] && port="$2"
  [[ "$port" =~ ^[0-9]+$ ]] || usage

  [ -d "$vaultDir" ] || { echo "error: vault dir not found: $vaultDir" >&2; exit 1; }
  [ -x "$VW_BIN" ] || { echo "error: vaultwarden binary not found: $VW_BIN" >&2; exit 1; }

  CERT_FILE="$CERT_DIR/localhost.crt"
  KEY_FILE="$CERT_DIR/localhost.key"

  # Generate a self-signed cert once; reuse it so the browser exception sticks.
  if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    mkdir -p "$CERT_DIR"
    ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout "$KEY_FILE" -out "$CERT_FILE" -days 365 \
      -subj "/CN=localhost" \
      -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1"
  fi

  export DATA_FOLDER="$vaultDir"
  export ROCKET_ADDRESS="127.0.0.1"
  export ROCKET_PORT="$port"
  export ROCKET_TLS="{certs=\"$CERT_FILE\",key=\"$KEY_FILE\"}"
  export DOMAIN="https://localhost:$port"
  export ROCKET_LOG="normal"
  export SIGNUPS_ALLOWED=false
  export WEB_VAULT_FOLDER
  export WEB_VAULT_ENABLED=true

  echo "Vault: $vaultDir"
  echo "URL:   https://localhost:$port"
  echo "Cert:  $CERT_FILE (accept the browser warning once)"
  echo "Log:   Ctrl-C to stop"

  exec "$VW_BIN"
''
