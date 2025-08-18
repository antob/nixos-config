{
  plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        disableNetrw = true;
        hijackCursor = true;
        syncRootWithCwd = true;

        filters.dotfiles = false;
        updateFocusedFile = {
          enable = true;
          updateRoot = false;
        };
        view = {
          width = 40;
          preserveWindowProportions = true;
        };
        renderer = {
          rootFolderLabel = false;
          highlightGit = true;
          indentMarkers = {
            enable = true;
          };
          icons = {
            glyphs = {
              default = "󰈚";
              folder = {
                default = "";
                empty = "";
                emptyOpen = "";
                open = "";
                symlink = "";
              };
              git = {
                unmerged = "";
              };
            };
          };
        };
      };
    };

    web-devicons = {
      enable = true;
      defaultIcon.icon = "󰈚";
      customIcons = {
        defaultIcon = {
          icon = "󰈚";
          name = "Default";
        };
        js = {
          icon = "󰌞";
          name = "js";
        };
        ts = {
          icon = "󰛦";
          name = "ts";
        };
        lock = {
          icon = "󰌾";
          name = "lock";
        };
      };
    };
  };
}
