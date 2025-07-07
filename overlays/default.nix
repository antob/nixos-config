{
  inputs,
}:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake:
      let
        legacyPackages = (flake.legacyPackages or { }).${final.system} or { };
        packages = (flake.packages or { }).${final.system} or { };
      in
      if legacyPackages != { } then legacyPackages else packages
    ) inputs;
  };

  # Adds pkgs.stable == inputs.nixpkgs-stable.legacyPackages.${pkgs.system}
  stable = final: _: {
    stable = inputs.nixpkgs-stable.legacyPackages.${final.system};
  };

  # Adds my custom packages
  additions = final: prev: import ../pkgs { pkgs = final; };

  # Modifies existing packages
  modifications = final: prev: {
    dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
      src = prev.fetchFromGitHub {
        owner = "antob";
        repo = "dmenu";
        rev = "cd3f248";
        sha256 = "sha256-OHvRuex2k72FJiVaMZkcmbpoKIgqpZzxrAImgg8XVeI=";
      };
    });
  };
}
