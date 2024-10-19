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

# Configure status bar
set -g status-right ''

## Keybindings
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

bind '|' split-window -v -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"

# Reload config file
bind r source-file ~/.config/tmux/tmux.conf
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

# Hooks
set-hook -g after-new-session "select-layout main-vertical"
set-hook -g after-new-window "select-layout main-vertical \; rename-window 'Tab'"
#set-hook -g after-split-window "select-layout \; swap-pane -U"
set-hook -g after-split-window "select-layout"

#set -g destroy-unattached on  # destroy orphaned sessions
set -g detach-on-destroy on   # exit from tmux when closing a session
set -g escape-time 0          # zero-out escape time delay
set -g renumber-windows on    # renumber all windows when any window is closed
set -g set-clipboard on       # use system clipboard

TMUX_FZF_LAUNCH_KEY="C-f"
