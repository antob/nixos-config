set-option -sa terminal-overrides ",xterm*:Tc"
set -g mouse on

# Set C-a as prefix
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# set vi-mode
set-window-option -g mode-keys vi

# do not auto-rename windows
set-option -g automatic-rename off

# Make the status line pretty and add some modules
set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_session}"

# Make splits even in main-vertical layout
set-option -g main-pane-width 50%

# Allow passthrough
set -g allow-passthrough on

# Tmux yank
#set -g @yank_action 'copy-selection' # Stay in copy-mode after yanking text
#set -g @yank_with_mouse on

# Preserve mouse selection and scroll position after mouse drag
unbind -T copy-mode-vi MouseDragEnd1Pane

## Keybindings

# Copying
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection

# Drag select and copy
bind-key -T copy-mode-vi MouseDragEnd1Pane \
	send-keys -X copy-selection-no-clear

# Double LMB select and copy (word)
bind-key -T copy-mode-vi DoubleClick1Pane \
	select-pane \; \
	send-keys -X select-word \; \
	send-keys -X copy-selection-no-clear
bind-key -n DoubleClick1Pane \
	select-pane \; \
	copy-mode -M \; \
	send-keys -X select-word \; \
	send-keys -X copy-selection-no-clear

# Triple LMB select and copy (line)
bind-key -T copy-mode-vi TripleClick1Pane \
	select-pane \; \
	send-keys -X select-line \; \
	send-keys -X copy-selection-no-clear
bind-key -n TripleClick1Pane \
	select-pane \; \
	copy-mode -M \; \
	send-keys -X select-line \; \
	send-keys -X copy-selection-no-clear

# Splits
bind '|' split-window -v -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"

# Reload config file
bind C-r source-file ~/.config/tmux/tmux.conf
# Cycle layout
bind -n \uE000 next-layout
# Spawn new pane
bind -n \uE010 split-window -v -c "#{pane_current_path}"
# Focus next pane
bind -n C-S-Right select-pane -Z -t :.+
# Focus previous pane
bind -n C-S-Left select-pane -Z -t :.-
# Toggle pane zoom
bind -n \uE011 resize-pane -Z
# Spawn new window
bind -n \uE020 new-window -c "#{pane_current_path}"
# Focus previous window
bind -n \uE021 previous-window
# Focus next window
bind -n \uE022 next-window

bind-key "C-s" run-shell "sesh connect \"$(
	sesh list -t | fzf-tmux -p 55%,60% \
		--no-sort --ansi --border-label ' Sessions ' --prompt '⚡  ' \
		--header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
		--bind 'tab:down,btab:up' \
		--bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
		--bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
		--bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
		--bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
		--bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .cache -E .stfolder -E .Trash -E .Trash-1000 . ~/Projects)' \
		--bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list -t)'
)\""

# Hooks
set-hook -g after-new-session "select-layout main-vertical"
set-hook -g after-new-window "select-layout main-vertical \; rename-window 'Tab'"
#set-hook -g after-split-window "select-layout \; swap-pane -U"
set-hook -g after-split-window "select-layout"
set-hook -g after-kill-pane "select-layout"
set-hook -g pane-exited "select-layout"

#set -g destroy-unattached on  # destroy orphaned sessions
set -g detach-on-destroy on   # exit from tmux when closing a session
set -g escape-time 0          # zero-out escape time delay
set -g renumber-windows on    # renumber all windows when any window is closed
set -g set-clipboard external # use system clipboard

TMUX_FZF_LAUNCH_KEY="C-f"
