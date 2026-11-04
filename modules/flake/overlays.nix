{ inputs, config, ... }:
let
  importChannel =
    input: final:
    import input {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: true;
        allowUnfree = true;
      };
    };
in
{
  flake.overlays = {
    # Aliases 'pkgs.inputs.${flake}' to that input's packages (or legacyPackages) for this system
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

    stable = final: _: { stable = importChannel inputs.nixpkgs-stable final; };
    next = final: _: { next = importChannel inputs.nixpkgs-next final; };
    prev = final: _: { prev = importChannel inputs.nixpkgs-prev final; };

    additions = final: _: import ../../pkgs { pkgs = final; };
  };

  flake.modules.nixos.overlays = {
    nixpkgs.overlays = builtins.attrValues config.flake.overlays;
  };
}
