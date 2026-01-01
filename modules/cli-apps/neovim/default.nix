{
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.neovim;
  alacritty = config.antob.tools.alacritty.enable;
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];

    antob.home.extraOptions = {
      imports = [
        ./options.nix
        ./utils.nix
        ./colorscheme.nix
        ./diagnostic.nix
        ./autocmd.nix
        ./filetypes.nix
        ./keymaps.nix
        ./lsp
        ./plugins
        ./syntax
      ];

      programs.neovim = {
        enable = true;
        vimAlias = true;
      };

      programs.alacritty.settings.keyboard.bindings = lib.mkIf alacritty [
        # Map <C-S-o> for nvim
        {
          key = "o";
          mods = "Control|Shift";
          chars = "\\u001b[79;5u";
        }
      ];
    };
  };
}
