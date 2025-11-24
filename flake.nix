{
  description = "My NixOS systems";

  inputs = {
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs Stable
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # NixPkgs Unstable (refreshed nixos-unstable)
    nixpkgs-next.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs Unstable (kept one step behind)
    nixpkgs-prev.url = "github:nixos/nixpkgs/0147c2f1d54b30b5dd6d4a8c8542e8d7edf93b5d";

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
    };

    # PaperWM
    paperwm = {
      url = "github:paperwm/PaperWM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix VSCode Extensions
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # Simple NixOS Mailserver
    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Niri
    niri.url = "github:sodiboo/niri-flake";

    # MangoWC
    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

      commonModules = with inputs; [
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        ./modules
      ];

    in
    {
      overlays = import ./overlays { inherit inputs; };
      packages = forEachSystem (pkgs: import ./pkgs { inherit pkgs; });
      formatter = forEachSystem (pkgs: pkgs.nixfmt-tree);

      nixosConfigurations = {
        laptob-fw = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/laptob-fw
          ];
        };

        desktob = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/desktob
          ];
        };

        hyllan = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/hyllan
          ];
        };

        wiggum = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/wiggum
          ];
        };

        install-iso = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "x86_64-linux";
          modules = commonModules ++ [
            ./hosts/install-iso
          ];
        };

        minimal-iso = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "x86_64-linux";
          modules = commonModules ++ [
            ./hosts/minimal-iso
          ];
        };

        laptob-qemu = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/laptob-qemu
          ];
        };
      };
    };
}
