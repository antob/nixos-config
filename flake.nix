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
    nixpkgs-prev.url = "github:nixos/nixpkgs/eaad089433ca2bb662274377d33df3d0e51ef28b";

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
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PiKVM
    kvmd = {
      url = "github:aostanin/kvmd.nix";
      inputs.nixos-hardware.follows = "nixos-hardware-pi";
    };

    # Clipperd - Clipboard sync between iPhone and Linux
    clipperd = {
      url = "github:antob/clipperd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Lanzaboote - Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Unopinionated Nix flake for infrastructure NixOS running on Raspberry Pi devices.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
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
      rpiLib = import ./lib { inherit (inputs.nixos-raspberrypi.inputs.nixpkgs) lib; };

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

      authorizedKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ==";
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

        pidesk = inputs.nixos-raspberrypi.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
            lib = rpiLib;
          };
          modules = [
            ./modules/features/rpi
            ./hosts/pidesk
          ];
        };

        rpi4-installer = inputs.nixos-raspberrypi.lib.nixosInstaller {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs outputs;
            lib = rpiLib;
          };
          modules = [
            {
              imports = with inputs.nixos-raspberrypi.nixosModules; [
                raspberry-pi-4.base
              ];

              sdImage.compressImage = false;
              boot.zfs.forceImportRoot = false;
              services.openssh = {
                enable = true;
                settings.PermitRootLogin = "yes";
              };
              users.users.root.openssh.authorizedKeys.keys = [
                authorizedKey
              ];
            }
          ];
        };
      };
    };
}
