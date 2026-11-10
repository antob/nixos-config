# Column-aware splits. A column is one top-level child of the window layout.
# Usage: tmux-columns new|down|right <pane-id>
#        tmux-columns swap <pane-id> left|right
#        tmux-columns snapshot [window-id] | closed
# Sizes are computed here because select-layout -E (tmux 3.8) leaves nested panes unresized.

cmd=$1
pane=${2:-}
flag=@columns_single
snap=@columns_layout

layout() { tmux display -p -t "$window" '#{window_layout}'; }

jqlib='
  def axis: if .t == "h" then "w" else "h" end;
  # Set size $s along $k, scaling children proportionally.
  def resize($k; $s):
    .[$k] = $s
    | if has("c") | not then .
      elif axis == $k then
        (.c | length) as $n | ($s - $n + 1) as $avail | ([.c[][$k]] | add) as $old
        | [.c[][$k] * $avail / $old | floor | if . < 1 then 1 else . end] as $sz
        | ($sz | .[-1] += $avail - add) as $sz
        | .c = [range($n) as $i | .c[$i] | resize($k; $sz[$i])]
      else .c |= map(resize($k; $s)) end;
  # Recompute positions from sizes.
  def place($x; $y):
    .x = $x | .y = $y
    | if has("c") | not then .
      else axis as $k
        | .c = (reduce .c[] as $c ({p: (if $k == "w" then $x else $y end), out: []};
            . as $a | .out += [$c | if $k == "w" then place($a.p; $y) else place($x; $a.p) end]
            | .p += $c[$k] + 1) | .out)
      end;
  def evenkids:
    axis as $k | (.c | length) as $n | (.[$k] - $n + 1) as $avail
    | .c = [range($n) as $i | .c[$i]
        | resize($k; ($avail / $n | floor) + (if $i < ($avail % $n) then 1 else 0 end))];
  # Even out the container holding pane $id.
  def even_around($id):
    [paths(type == "object" and has("c") and any(.c[]; .I? == $id))][0] as $p
    | setpath($p; getpath($p) | evenkids) | .L |= place(.x; .y);
  def hbox: {t: "h", x: .[0].x, y: .[0].y, h: .[0].h, w: ((map(.w) | add) + length - 1), c: .};
  def rootidx($id): .L.c | map(any(..; .I? == $id)) | index(true);
  def panes: [.. | objects | select(.t? == "p") | .I];
  # Even each container (of 3+ cells) in $old that lost a whole cell; 2-cell ones collapse by themselves.
  def closed($old):
    ($old.L | panes) as $before | (.L | panes) as $now
    | [$old.L | .. | objects | select(has("c") and (.c | length) >= 3)
        | [.c[] | panes] | select(any(.[]; all(.[]; IN($now[]) | not)))
        | map(.[] | select(IN($now[]))) | sort] as $targets
    | if ($before - $now | length) == 0 or ($now - $before | length) > 0 or ($targets | length) == 0
      then "unchanged"
      else
        reduce $targets[] as $s (.;
          [paths(type == "object" and has("c") and (panes | sort) == $s)][0] as $p
          | if $p then setpath($p; getpath($p) | evenkids) else . end)
        | .L |= place(.x; .y)
      end;
  # If the active pane in $old is gone, pick the nearest survivor (earlier first) in its column, else anywhere.
  def focus($old):
    ($old.L | panes) as $before | (.L | panes) as $now
    | ([$old.L | .. | objects | select(.a? == true) | .I][0]) as $act
    | if $act == null or ($now | index($act)) != null then ""
      else
        ($before | index($act)) as $i
        | def nearest($xs): [$xs[] | select(IN($now[]))]
            | sort_by(. as $p | ($before | index($p)) - $i | if . < 0 then -2 * . - 1 else 2 * . end)
            | .[0] // "";
        ($old.L | if .t == "h" then [.c[] | panes | select(index($act) != null)][0] else panes end) as $col
        | nearest($col) as $c
        | if $c != "" then $c else nearest($before) end
      end;
'

query() { layout | jq -r --arg id "$1" "$jqlib $2"; }

# Rewrite the layout with jq program $3 (pane id $1 and column index $2 available).
apply() { tmux select-layout -t "$window" "$(layout | jq -c --arg id "$1" --argjson k "$2" "$jqlib $3")"; }

# New panes start as a placeholder and get the shell once the layout is final;
# a shell started before the resize leaves a duplicate wrapped prompt behind.
split() { tmux split-window -P -F '#{pane_id}' "$@" cat; }

start_shell() {
  local shell command
  command=$(tmux show -gqv default-command)
  if [ -z "$command" ]; then
    shell=$(tmux show -gqv default-shell)
    command="exec -a -${shell##*/} $shell"
  fi
  tmux respawn-pane -k -t "$1" -c "$dir" "$command"
}

# Remember layouts (and the active pane), so a close can tell which container lost a pane.
snapshot_all() {
  local w
  for w in ${1:-$(tmux list-windows -a -F '#{window_id}')}; do
    window=$w
    tmux set -w -t "$w" "$snap" "$(layout)"
  done
}

case $cmd in
snapshot)
  snapshot_all "$pane"
  exit
  ;;
closed)
  for w in $(tmux list-windows -a -F '#{window_id}'); do
    window=$w
    old=$(tmux show -wqv -t "$w" "$snap")
    [ -n "$old" ] || continue
    next=$(layout | jq -c --argjson old "$old" "$jqlib closed(\$old)")
    if [ "$next" != '"unchanged"' ]; then tmux select-layout -t "$w" "$next"; fi
    target=$(layout | jq -r --argjson old "$old" "$jqlib focus(\$old)")
    if [ -n "$target" ]; then tmux select-pane -t "$target"; fi
  done
  snapshot_all
  exit
  ;;
esac

read -r window dir < <(tmux display -p -t "$pane" '#{window_id} #{pane_current_path}')

case $cmd in
swap)
  # Columns keep their widths; no-op at the edges, when zoomed, or in a single split column.
  [ "$(tmux display -p -t "$window" '#{window_zoomed_flag}')" = 0 ] || exit 0
  [ -z "$(tmux show -wqv -t "$window" "$flag")" ] || exit 0
  read -r k n < <(query "$pane" 'if .L.t == "h" then "\(rootidx($id)) \(.L.c | length)" else "0 1" end')
  case ${3:-} in
  left) k=$((k - 1)) ;;
  right) ;;
  *) exit 1 ;;
  esac
  if [ "$k" -ge 0 ] && [ "$k" -lt $((n - 1)) ]; then
    apply "$pane" "$k" '.L.c |= (.[:$k] + [.[$k + 1], .[$k]] + .[$k + 2:]) | .L |= place(.x; .y)'
    snapshot_all "$window"
  fi
  exit
  ;;
new)
  read -r type k < <(query "$pane" '.L.t + " " + (if .L.t == "h" then rootidx($id) else -1 end | tostring)')
  single=$(tmux show -wqv -t "$window" "$flag")
  new=$(split -h -f -t "$pane")
  if [ "$type" = h ] && [ -n "$single" ]; then
    # The whole window was one column split side by side: box it before adding the new column.
    apply "$new" 0 '.L.c |= ([.[:-1] | hbox] + .[-1:]) | even_around($id)'
  elif [ "$type" = h ]; then
    apply "$new" "$k" '.L.c |= (.[-1:] as $n | .[:-1] | .[:$k + 1] + $n + .[$k + 1:]) | even_around($id)'
  else
    apply "$new" 0 'even_around($id)'
  fi
  tmux set -wu -t "$window" "$flag"
  ;;
down)
  new=$(split -v -t "$pane")
  apply "$new" 0 'even_around($id)'
  ;;
right)
  state=$(query "$pane" 'if .L.t == "p" then "alone" elif .L.t == "h" and any(.L.c[]; .I == $id) then "column" else "nested" end')
  single=$(tmux show -wqv -t "$window" "$flag")
  new=$(split -h -t "$pane")
  if [ "$state" = alone ]; then
    # tmux cannot nest a split under a single root, so remember this window is still one column.
    tmux set -w -t "$window" "$flag" 1
    apply "$new" 0 'even_around($id)'
  elif [ "$state" = column ] && [ -z "$single" ]; then
    k=$(query "$pane" 'rootidx($id)')
    apply "$new" "$k" '.L.c |= (.[:$k] + [.[$k:$k + 2] | hbox] + .[$k + 2:]) | even_around($id)'
  else
    apply "$new" 0 'even_around($id)'
  fi
  ;;
*)
  echo "usage: tmux-columns new|down|right <pane-id> | swap <pane-id> left|right | snapshot | closed" >&2
  exit 1
  ;;
esac

start_shell "$new"
snapshot_all
