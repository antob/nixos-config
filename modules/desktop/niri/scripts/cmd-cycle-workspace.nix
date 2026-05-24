{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-cycle-workspace" ''
  # Cycle niri workspace focus forward (default) or backward.
  # Usage: cmd-cycle-workspace [forward|backward]

  set -euo pipefail

  direction="$1"

  json=$(niri msg --json workspaces)

  focused=$(echo "$json" | jq '[.[] | select(.is_focused == true)][0].id')
  sorted=$(echo "$json" | jq 'sort_by(.id)')
  total=$(echo "$json" | jq 'length')

  pos=$(echo "$sorted" | jq --argjson id "$focused" '[.[] | .id] | index($id)')

  if [ "$direction" = "backward" ]; then
      if [ "$pos" -gt 0 ]; then
          target=$(( pos - 1 ))
      else
          target=$(( total - 1 ))
      fi
  else
      if [ "$pos" -lt $(( total - 1 )) ]; then
          target=$(( pos + 1 ))
      else
          target=0
      fi
  fi

  target_id=$(echo "$sorted" | jq --argjson idx "$target" '[.[]][$idx].id')

  niri msg action focus-workspace "$target_id"
''
