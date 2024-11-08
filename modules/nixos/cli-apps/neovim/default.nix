{ options
, config
, pkgs
, lib
, inputs
, ...
}:
with lib;
with lib.antob; let
  cfg = config.antob.cli-apps.neovim;

  insertTable = file:
    builtins.concatStringsSep "\n"
      [
        "insert(P, (function()"
        (lib.strings.fileContents file)
        "end)())"
      ];

  extraConfig = builtins.concatStringsSep "\n"
    (builtins.map lib.strings.fileContents (lib.snowfall.fs.get-files ./config));

  extraPlugins = builtins.concatStringsSep "\n" (
    [
      "function insert(t1, t2) for _, v in ipairs(t2) do table.insert(t1, v) end end"
      "P = {}"
    ] ++
    (builtins.map insertTable (lib.snowfall.fs.get-files ./plugins)) ++
    [ "return P" ]
  );

  chadrcConfig = lib.strings.fileContents ./chad-config.lua;
in
{
  options.antob.cli-apps.neovim = with types; {
    enable = mkEnableOption "Whether or not to enable neovim.";
  };

  imports = [
  ];

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.nvchad = {
        enable = true;
        backup = false;
        extraPackages = with pkgs; [
          nodePackages.bash-language-server
          emmet-language-server
          vscode-langservers-extracted
          nixd
        ];

        inherit chadrcConfig;
        inherit extraConfig;
        inherit extraPlugins;
      };
    };

    environment.shellAliases = {
      vim = "nvim";
    };

    environment.systemPackages = with pkgs; [
      universal-ctags
    ];
  };
}
