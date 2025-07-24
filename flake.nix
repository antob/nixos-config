{
  description = "My NixOS systems";

  inputs = {
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs Stable
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware Configuration
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Impermanence
    impermanence.url = "github:nix-community/impermanence";

    # Nix User Repository (NUR)
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Betterfox
    betterfox = {
      url = "github:HeitorAugustoLN/betterfox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nixvim
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PaperWM
    paperwm = {
      url = "github:paperwm/PaperWM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix VSCode Extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      lib = import ./lib { inherit (nixpkgs) lib; };

      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      );
    in
    {
      overlays = import ./overlays { inherit inputs; };
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);

      nixosConfigurations = {
        laptob-fw = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = [
            ./hosts/laptob-fw
          ];
        };

        hyllan = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = [
            ./hosts/hyllan
          ];
        };

        install-iso = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "x86_64-linux";
          modules = [
            ./hosts/install-iso
          ];
        };

        minimal-iso = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "x86_64-linux";
          modules = [
            ./hosts/minimal-iso
          ];
        };

        laptob-qemu = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = [
            ./hosts/laptob-qemu
          ];
        };
      };
    };
}
