set-option -sa terminal-overrides ",xterm*:Tc"
set -g mouse on

unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Vim style pane selection
bind h select-pane -L
bind j select-pane -D 
bind k select-pane -U
bind l select-pane -R

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Use Alt-arrow keys without prefix key to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Shift arrow to switch windows
bind -n S-Left  previous-window
bind -n S-Right next-window

# Shift Alt vim keys to switch windows
bind -n M-H previous-window
bind -n M-L next-window

# set vi-mode
set-window-option -g mode-keys vi
# keybindings
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

bind '|' split-window -v -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"

# configure onedark theme
set -g @onedark_widgets ""

# configure catppuchin theme
#set -g @catppuccin_flavour 'mocha' # or frappe, macchiato, latte
#set -g @catppuccin_status_left_separator "█"

set -g detach-on-destroy off  # don't exit from tmux when closing a session
set -g escape-time 0          # zero-out escape time delay
set -g renumber-windows on    # renumber all windows when any window is closed
set -g set-clipboard on       # use system clipboard
#set -g status-position top    # macOS / darwin style
#set -g status-right ''        # empty

set -g @t-fzf-prompt '  '
