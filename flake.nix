{
  description = "NixOS configuration";

  inputs = {
    # NixPkgs Unstable (nixos-unstable)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Impermanence
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});
    in rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forEachPkgs (pkgs: import ./pkgs { inherit pkgs; });

      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forEachPkgs (pkgs: import ./shell.nix { inherit pkgs; });

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays;

      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;

      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # Laptob
        laptob = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./systems/laptob
            # nixosModules.home
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs outputs; };
                users.tob = import ./home-manager/home.nix;
              };
            }
          ];
        };
      };
    };
}
