{ pkgs, ... }:

pkgs.writeShellScriptBin "consume-or-expel-window" ''
  # Script name: consume-or-expel-window
  # Description: Consume or expel the currently active window to/from a column. 
  # Contributors: Tobias Lindholm

  DIR="$1"

  ACTIVE=$(${pkgs.hyprland}/bin/hyprctl activewindow -j)
  LAYOUT=$(${pkgs.hyprland}/bin/hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r '.tiledLayout')
  X=$(echo "$ACTIVE" | ${pkgs.jq}/bin/jq '.at[0]')
  WS=$(echo "$ACTIVE" | ${pkgs.jq}/bin/jq '.workspace.id')
  ADDR=$(echo "$ACTIVE" | ${pkgs.jq}/bin/jq -r '.address')

  COUNT=$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq --argjson ws "$WS" --argjson x "$X" \
    '[.[] | select(.workspace.id == $ws and .floating == false and .at[0] == $x)] | length')

  if [ "$COUNT" -gt 1 ] && [ "$LAYOUT" = "scrolling" ] ; then
    ${pkgs.hyprland}/bin/hyprctl dispatch layoutmsg promote
    if [ "$DIR" = "l" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch layoutmsg swapcol l
    fi
    ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "address:$ADDR"
  else
    ${pkgs.hyprland}/bin/hyprctl dispatch movewindow "$DIR"
  fi
''
