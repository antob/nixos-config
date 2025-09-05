{
  plugins = {
    nvim-tree = {
      enable = true;
      settings = {
        filters.dotfiles = false;
        view = {
          width = 40;
        };
        renderer = {
          icons = {
            glyphs = {
              default = "󰈚";
              folder = {
                default = "";
                empty = "";
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
