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
    nixpkgs-prev.url = "github:nixos/nixpkgs/f9a75f41be3a74eab55d3a7679d34ad6cc0da977";

    # Flake Parts
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Import Tree - import every module in a directory
    import-tree.url = "github:vic/import-tree";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware Configuration
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Preservation
    preservation.url = "github:nix-community/preservation";

    # Stylix - System-wide colour and font theming
    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nur.follows = "nur";
        flake-parts.follows = "flake-parts";
        firefox-gnome-theme.follows = "firefox-gnome-theme";
      };
    };

    # Firefox GNOME theme - tracks upstream so it keeps up with Firefox releases
    firefox-gnome-theme = {
      url = "github:rafaelmardojai/firefox-gnome-theme";
      flake = false;
    };

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

    # Monique - Graphical monitor configurator
    monique.url = "github:ToRvaLDz/monique";

    # Bubblewrap-based sandboxing utilities
    jail-nix.url = "sourcehut:~alexdavid/jail.nix";

    # Pi Coding Agent
    pi-coding-agent = {
      url = "github:earendil-works/pi/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LLM Agents - A collection of agents for various LLMs
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Copyparty - A self-hosted file sharing web server
    copyparty = {
      url = "github:9001/copyparty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # PiKVM
    kvmd.url = "github:aostanin/kvmd.nix";

    # Clipperd - Clipboard sync between iPhone and Linux
    clipperd = {
      url = "github:antob/clipperd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Lanzaboote - Secure boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Unopinionated Nix flake for infrastructure NixOS running on Raspberry Pi devices.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
