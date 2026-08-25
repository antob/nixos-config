{
  description = "My NixOS systems";

  inputs = {
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs Stable
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    # NixPkgs Unstable (refreshed nixos-unstable)
    nixpkgs-next.url = "github:nixos/nixpkgs/nixos-unstable";

    # NixPkgs Unstable (kept one step behind)
    nixpkgs-prev.url = "github:nixos/nixpkgs/0e251e24a4f24e036a084b6b4b2d2491af4167f4";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware Configuration
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    # Pinned version used by Rpi builds to avoid rebuilding the kernel on every update.
    nixos-hardware-pi.url = "github:NixOS/nixos-hardware/0471accf8d0a8210b31d947497d179ecc99e0021";

    # Preservation
    preservation.url = "github:nix-community/preservation";

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

    # Hyprnix
    hyprnix.url = "github:hyprwm/hyprnix";

    # DMS plugins
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Monique - Graphical monitor configurator
    monique.url = "github:ToRvaLDz/monique";

    # Bubblewrap-based sandboxing utilities
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

    # LLM Agents - A collection of agents for various LLMs
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Lumen - A fast terminal diff viewer and code review TUI, written in Rust.
    lumen = {
      url = "github:jnsahaj/lumen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Copyparty - A self-hosted file sharing web server
    copyparty.url = "github:9001/copyparty";

    # PiKVM
    kvmd = {
      url = "github:aostanin/kvmd.nix";
      inputs.nixos-hardware.follows = "nixos-hardware-pi";
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
        "x86_64-linux"
        "aarch64-linux"
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
        laptob = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          modules = commonModules ++ [
            ./hosts/laptob
          ];
        };

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

        pihole = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "aarch64-linux";
          modules = commonModules ++ [
            ./hosts/pihole
          ];
        };

        pikvm = lib.nixosSystem {
          specialArgs = { inherit inputs outputs lib; };
          system = "aarch64-linux";
          modules = commonModules ++ [
            ./hosts/pikvm
          ];
        };
      };
    };
}
