# ████████╗███╗   ███╗██╗   ██╗██╗  ██╗
# ╚══██╔══╝████╗ ████║██║   ██║╚██╗██╔╝
#    ██║   ██╔████╔██║██║   ██║ ╚███╔╝
#    ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗
#    ██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗
#    ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝
# Terminal multiplexer
# https://github.com/tmux/tmux

set -g prefix C-s
unbind C-b
bind C-s send-prefix

set -g base-index 1           # start indexing windows at 1 instead of 0
set -g detach-on-destroy off  # don't exit from tmux when closing a session
set -g escape-time 0          # zero-out escape time delay
set -g history-limit 1000000  # significantly increase history size
set -g mouse on               # enable mouse support
set -g renumber-windows on    # renumber all windows when any window is closed
set -g set-clipboard on       # use system clipboard
set -g status-interval 2      # update status every 2 seconds
set -g status-left-length 200 # increase status line length
set -g status-position top    # macOS / darwin style
set -g status-right ''        # empty

set -g pane-active-border-style 'fg=magenta,bg=default'
set -g pane-border-style 'fg=brightblack,bg=default'
set -g status-style 'bg=default' # transparent
set -g window-status-current-format '#[fg=magenta]#W'
set -g window-status-format '#[fg=gray]#W'
set -g mode-style bg=default,fg=yellow
set -g message-style bg=default,fg=yellow
set -g message-command-style bg=default,fg=yellow

set -g status-left '#[fg=blue,bold]#S #[fg=white,nobold]'

set-option -g default-terminal 'screen-256color'
set-option -g terminal-overrides ',xterm-256color:RGB'

bind '%' split-window -c '#{pane_current_path}' -h
bind '"' split-window -c '#{pane_current_path}'
bind c new-window -c '#{pane_current_path}'
bind g new-window -n '' gitui
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -n M-z resize-pane -Z

bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
bind-key x kill-pane # skip "kill-pane 1? (y/n)" prompt (cmd+w)

set -g @t-fzf-prompt '  '