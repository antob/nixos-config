{
  keymaps = [
    # Center buffer after C-u/d
    {
      mode = "n";
      key = "<C-d>";
      action = "<C-d>zz";
    }
    {
      mode = "n";
      key = "<C-u>";
      action = "<C-u>zz";
    }

    # Reselect visual block after indent/outdent
    {
      mode = "v";
      key = "<";
      action = "<gv";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
    }

    # Move up/down on VISUAL line instead of a ACTUAL line
    {
      mode = "n";
      key = "j";
      action = "v:count == 0 ? 'gj' : 'j'";
      options = {
        expr = true;
        silent = true;
      };
    }
    {
      mode = "n";
      key = "k";
      action = "v:count == 0 ? 'gk' : 'k'";
      options = {
        expr = true;
        silent = true;
      };
    }

    # Keep cursor position when joining lines
    {
      mode = "n";
      key = "J";
      action = "mzJ`z";
    }

    # Keep search term center in screen
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
    }

    # Move in visual mode
    {
      mode = "v";
      key = "J";
      action = ":m '>+1<CR>gv=gv";
    }
    {
      mode = "v";
      key = "K";
      action = ":m '<-2<CR>gv=gv";
    }

    # Do not store deleted text when pasting
    {
      mode = "x";
      key = "<leader>p";
      action = "\"_dP";
    }

    # Yank to system clipboard
    {
      mode = "n";
      key = "<leader>y";
      action = "\"+y";
      options.desc = "Yank to system clipboard";
    }
    {
      mode = "v";
      key = "<leader>y";
      action = "\"+y";
      options.desc = "Yank to system clipboard";
    }

    # Delete to void register
    {
      mode = "n";
      key = "<leader>d";
      action = "\"_d";
      options.desc = "Delete to void register";
    }
    {
      mode = "v";
      key = "<leader>d";
      action = "\"_d";
      options.desc = "Delete to void register";
    }

    # Never press Q
    {
      mode = "n";
      key = "Q";
      action = "<nop>";
    }

    # Clear highlight
    {
      mode = "i";
      key = "jk";
      action = "<CMD>noh<CR><ESC>";
      options.desc = "Normal mode and clear highlight";
    }
    {
      mode = "i";
      key = "<ESC>";
      action = "<CMD>noh<CR><ESC>";
      options.desc = "Normal mode and clear highlight";
    }
    {
      mode = "n";
      key = "<ESC>";
      action = "<CMD>noh<CR><ESC>";
      options.desc = "Normal mode and clear highlight";
    }

    # Navigation
    {
      mode = "i";
      key = "<C-b>";
      action = "<ESC>^i";
      options.desc = "Move to beginning of line";
    }
    {
      mode = "i";
      key = "<C-e>";
      action = "<End>";
      options.desc = "Move to end of line";
    }
    {
      mode = "n";
      key = "<C-h>";
      action = "<C-w>h";
      options.desc = "Switch window left";
    }
    {
      mode = "n";
      key = "<C-l>";
      action = "<C-w>l";
      options.desc = "Switch window right";
    }
    {
      mode = "n";
      key = "<C-j>";
      action = "<C-w>j";
      options.desc = "Switch window down";
    }
    {
      mode = "n";
      key = "<C-k>";
      action = "<C-w>k";
      options.desc = "Switch window up";
    }

    {
      mode = "n";
      key = "<Esc>";
      action = "<cmd>noh<CR>";
      options.desc = "Clear highlights";
    }

    {
      mode = "n";
      key = "<C-s>";
      action = "<cmd>w<CR>";
      options.desc = "Save file";
    }
    {
      mode = "n";
      key = "<C-c>";
      action = "<cmd>%y+<CR>";
      options.desc = "Copy whole file";
    }

    # Splits
    {
      mode = "n";
      key = "--";
      action = "<CMD>split<CR>";
      options.desc = "Split window horizontally";
    }
    {
      mode = "n";
      key = "\\\\";
      action = "<CMD>vsplit<CR>";
      options.desc = "Split window vertically";
    }

    # Buffer
    {
      mode = "n";
      key = "<S-h>";
      action = "<CMD>bprevious<CR>";
      options.desc = "Previous Buffer";
    }
    {
      mode = "n";
      key = "<S-l>";
      action = "<CMD>bnext<CR>";
      options.desc = "Next Buffer";
    }
    {
      mode = "n";
      key = "<leader>bb";
      action = "<CMD>e #<CR>";
      options.desc = "Switch To Other Buffer";
    }
    {
      mode = "n";
      key = "<leader>bd";
      action.__raw = ''
        function()
          Snacks.bufdelete()
        end
      '';
      options.desc = "Delete Buffer";
    }
    {
      mode = "n";
      key = "<leader>bD";
      action.__raw = ''
        function()
          Snacks.bufdelete.all()
        end
      '';
      options.desc = "Delete all Buffers";
    }
    {
      mode = "n";
      key = "<leader>bo";
      action.__raw = ''
        function()
          Snacks.bufdelete.other()
        end
      '';
      options.desc = "Delete other Buffers";
    }

    # Tabs
    {
      mode = "n";
      key = "<leader><tab>l";
      action = "<CMD>tablast<CR>";
      options.desc = "Last Tab";
    }
    {
      mode = "n";
      key = "<leader><tab>o";
      action = "<CMD>tabonly<CR>";
      options.desc = "Close Other Tabs";
    }
    {
      mode = "n";
      key = "<leader><tab>f";
      action = "<CMD>tabfirst<CR>";
      options.desc = "First Tab";
    }
    {
      mode = "n";
      key = "<leader><tab><tab>";
      action = "<CMD>tabnew<CR>";
      options.desc = "New Tab";
    }
    {
      mode = "n";
      key = "<leader><tab>]";
      action = "<CMD>tabnext<CR>";
      options.desc = "Next Tab";
    }
    {
      mode = "n";
      key = "<leader><tab>c";
      action = "<CMD>tabclose<CR>";
      options.desc = "Close Tab";
    }
    {
      mode = "n";
      key = "<leader><tab>[";
      action = "<CMD>tabprevious<CR>";
      options.desc = "Previous Tab";
    }

    # Telescope
    {
      mode = "n";
      key = "<leader>fw";
      action = "<cmd>Telescope live_grep<CR>";
      options.desc = "Telescope live grep";
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<CR>";
      options.desc = "Telescope find buffers";
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<CR>";
      options.desc = "Telescope help page";
    }
    {
      mode = "n";
      key = "<leader>fk";
      action = "<cmd>Telescope keymaps<CR>";
      options.desc = "Telescope find keymaps";
    }
    {
      mode = "n";
      key = "<leader>fm";
      action = "<cmd>Telescope marks<CR>";
      options.desc = "Telescope find marks";
    }
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<CR>";
      options.desc = "Telescope find files";
    }
    {
      mode = "n";
      key = "<C-p>";
      action = "<cmd>Telescope find_files<CR>";
      options.desc = "Telescope find files";
    }
    {
      mode = "n";
      key = "<leader>fo";
      action = "<cmd>Telescope oldfiles<CR>";
      options.desc = "Telescope find oldfiles";
    }
    {
      mode = "n";
      key = "<leader>fa";
      action = "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>";
      options.desc = "Telescope find all files";
    }
    {
      mode = "n";
      key = "<leader>fz";
      action = "<cmd>Telescope current_buffer_fuzzy_find<CR>";
      options.desc = "Telescope find in current buffer";
    }
    {
      mode = "n";
      key = "<leader>gc";
      action = "<cmd>Telescope git_commits<CR>";
      options.desc = "Telescope git commits";
    }
    {
      mode = "n";
      key = "<leader>gf";
      action = "<cmd>Telescope git_bcommits<CR>";
      options.desc = "Telescope current file git commits";
    }
    {
      mode = "n";
      key = "<leader>gs";
      action = "<cmd>Telescope git_status<CR>";
      options.desc = "Telescope git status";
    }
    {
      mode = "n";
      key = "<leader>dd";
      action = "<cmd>Telescope diagnostics<CR>";
      options.desc = "Telescope diagnostics";
    }

    # Whichkey
    {
      mode = "n";
      key = "<leader>wk";
      action = "<cmd>WhichKey<CR>";
      options.desc = "Whichkey all keymaps";
    }

    # Conform
    {
      mode = "n";
      key = "<leader>=";
      action = "<cmd>Format<CR>";
      options.desc = "Format file";
    }

    # Git
    {
      mode = "n";
      key = "<leader>gg";
      action.__raw = ''
        function()
          Snacks.lazygit()
        end
      '';
      options.desc = "LazyGit";
    }
    {
      mode = "n";
      key = "<leader>gb";
      action.__raw = ''
        function()
          Snacks.git.blame_line()
        end
      '';
      options.desc = "Git Blame Line";
    }

    # Undotree
    {
      mode = "n";
      key = "<leader>u";
      action = "<CMD>UndotreeToggle<CR>";
      options.desc = "UndoTree Toggle";
    }

    # NvimTree
    {
      mode = "n";
      key = "<leader>e";
      action = "<CMD>NvimTreeToggle<CR>";
      options.desc = "NvimTree Toggle";
    }
    {
      mode = "n";
      key = "<C-b>";
      action = "<CMD>NvimTreeToggle<CR>";
      options.desc = "NvimTree Toggle";
    }

    # MarkdownPreview
    {
      mode = "n";
      key = "<leader>mp";
      action = "<CMD>MarkdownPreviewToggle<CR>";
      options.desc = "Toggle markdown preview";
    }
  ];
}
