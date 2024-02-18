{
  description = "My NixOS systems";

  inputs = {
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Generate System Images
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Snowfall Lib
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence
    impermanence.url = "github:nix-community/impermanence";

    # Devenv
    devenv = {
      url = "github:cachix/devenv/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # auto-cpufreq
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # power-profiles-daemon (until version > 0.13)
    power-profiles-daemon = {
      flake = false;
      url = "gitlab:upower/power-profiles-daemon?ref=b3df9190e7fc2cddfc987243bca405267cc1db85&host=gitlab.freedesktop.org";
      # url = "gitlab:upower/power-profiles-daemon?ref=9a4229339b486c97b0c25e41211ea2152d9c414a&host=gitlab.freedesktop.org";
    };

    # Nix User Repository (NUR)
    nur.url = "github:nix-community/NUR";

    # System Deployment
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;
        src = ./.;

        snowfall.namespace = "antob";
      };
    in
    lib.mkFlake {
      channels-config.allowUnfree = true;

      overlays = with inputs; [
        nur.overlay
      ];

      systems.nixos.modules = with inputs; [
        home-manager.nixosModules.home-manager
        nur.nixosModules.nur
      ];


      deploy = lib.mkDeploy { inherit (inputs) self; };

      checks =
        builtins.mapAttrs
          (system: deploy-lib:
            deploy-lib.deployChecks inputs.self.deploy)
          inputs.deploy-rs.lib;
    };
}
