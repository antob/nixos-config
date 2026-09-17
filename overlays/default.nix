{
  inputs,
}:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.stdenv.hostPlatform.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.stdenv.hostPlatform.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake:
      let
        inherit (final.stdenv.hostPlatform) system;
        legacyPackages = (flake.legacyPackages or { }).${system} or { };
        packages = (flake.packages or { }).${system} or { };
      in
      if legacyPackages != { } then legacyPackages else packages
    ) inputs;
  };

  stable = final: _: {
    stable = import inputs.nixpkgs-stable {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: true;
        allowUnfree = true;
      };
    };
  };

  pkgs-next = final: _: {
    pkgs-next = import inputs.nixpkgs-next {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: true;
        allowUnfree = true;
      };
    };
  };

  pkgs-prev = final: _: {
    pkgs-prev = import inputs.nixpkgs-prev {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: true;
        allowUnfree = true;
      };
    };
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

    # TODO: Temporary workaround for sops-nix. Remove whenthis PR lands:
    # https://github.com/Mic92/sops-nix/issues/983
    buildGo125Module = prev.buildGoModule;
  };
}
