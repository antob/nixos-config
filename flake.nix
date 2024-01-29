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
      url = "gitlab:upower/power-profiles-daemon?host=gitlab.freedesktop.org";
    };

    # Nix User Repository (NUR)
    nur.url = "github:nix-community/NUR";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall.namespace = "antob";

      channels-config.allowUnfree = true;

      overlays = with inputs; [
        nur.overlay
      ];

      systems.nixos.modules = with inputs; [
        home-manager.nixosModules.home-manager
        nur.nixosModules.nur
      ];
    };
}
