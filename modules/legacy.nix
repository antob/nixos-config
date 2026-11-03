# Temporary: the pre-dendritic outputs, removed once everything is migrated.
{ inputs, config, ... }:
let
  inherit (inputs) nixpkgs;

  # Only the legacy tree needs these; they go away with it.
  legacyLib =
    base:
    base.extend (
      _: _:
      config.flake.lib
      // {
        hyllanBackupsBaseRepo = "s3:hel1.your-objectstorage.com/antob-hyllan-backups";

        scanPaths =
          path:
          map (f: (path + "/${f}")) (
            builtins.attrNames (
              base.filterAttrs (
                path: type: type == "directory" || (path != "default.nix" && base.hasSuffix ".nix" path)
              ) (builtins.readDir path)
            )
          );

        getFiles =
          path:
          let
            entries = if builtins.pathExists path then builtins.readDir path else { };
          in
          base.mapAttrsToList (name: _: "${path}/${name}") (
            base.filterAttrs (_: kind: kind == "regular") entries
          );
      }
    );

  lib = legacyLib nixpkgs.lib;
  rpiLib = legacyLib inputs.nixos-raspberrypi.inputs.nixpkgs.lib;
  rpiNixosSystem = inputs.nixos-raspberrypi.lib.nixosSystem;
  rpiNixosInstaller = inputs.nixos-raspberrypi.lib.nixosInstaller;

  commonModules = [
    config.aspects.nixos.base
    config.aspects.nixos.env
    ./_legacy
  ];

  authorizedKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ==";
in
{
  flake = {
    nixosConfigurations = {
      laptob = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        modules = commonModules ++ [
          config.aspects.nixos.laptob
        ];
      };

      desktob = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        modules = commonModules ++ [
          config.aspects.nixos.desktob
        ];
      };

      hyllan = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        modules = commonModules ++ [
          config.aspects.nixos.hyllan
        ];
      };

      wiggum = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        modules = commonModules ++ [
          config.aspects.nixos.wiggum
        ];
      };

      install-iso = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        system = "x86_64-linux";
        modules = commonModules ++ [
          config.aspects.nixos.install-iso
        ];
      };

      minimal-iso = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        system = "x86_64-linux";
        modules = commonModules ++ [
          config.aspects.nixos.minimal-iso
        ];
      };

      laptob-qemu = lib.nixosSystem {
        specialArgs = { inherit inputs lib; };
        modules = commonModules ++ [
          config.aspects.nixos.laptob-qemu
        ];
      };

      pihole = rpiNixosSystem {
        specialArgs = {
          inherit inputs;
          lib = rpiLib;
        };
        system = "aarch64-linux";
        modules = [
          config.aspects.nixos.base
          config.aspects.nixos.pihole
        ];
      };

      pikvm = rpiNixosSystem {
        specialArgs = {
          inherit inputs;
          lib = rpiLib;
        };
        system = "aarch64-linux";
        modules = [
          config.aspects.nixos.base
          config.aspects.nixos.pikvm
        ];
      };

      pidesk = rpiNixosSystem {
        specialArgs = {
          inherit inputs;
          lib = rpiLib;
        };
        system = "aarch64-linux";
        modules = [
          config.aspects.nixos.base
          config.aspects.nixos.pidesk
        ];
      };

      rpi4-installer = rpiNixosInstaller {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs;
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
