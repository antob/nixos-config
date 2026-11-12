{
  flake.modules.nixos.xdg-open-browser =
    { lib, pkgs, ... }:
    let
      # Outside GNOME/KDE, xdg-open prefers the x-scheme-handler default over $BROWSER.
      xdg-open = pkgs.writeShellScriptBin "xdg-open" ''
        if [[ $# -eq 1 && ''${1,,} =~ ^https?:// ]]; then
          IFS=: read -ra browsers <<< "''${BROWSER:-}"
          for browser in "''${browsers[@]}"; do
            [[ -n $browser && ''${browser##*/} != xdg-open ]] || continue
            command -v "$browser" >/dev/null && exec "$browser" "$1"
          done
        fi
        exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
      '';
    in
    {
      environment.systemPackages = [ (lib.hiPrio xdg-open) ];
    };
}
