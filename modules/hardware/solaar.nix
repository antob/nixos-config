{
  flake.modules.nixos.solaar = {
    programs.solaar.enable = true;

    antob.persistence.home.directories = [
      ".config/solaar"
    ];
  };
}
