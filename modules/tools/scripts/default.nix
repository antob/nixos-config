{
  flake.modules.nixos.scripts =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    let
      cp = pkgs.callPackage;
    in
    {
      config = {
        environment.systemPackages = [
          (cp ./_files/backup-status { })
          (cp ./_files/bb.nix { })
          (cp ./_files/catbin.nix { })
          (cp ./_files/getsong.nix { })
          (cp ./_files/sfx.nix { })
          (cp ./_files/timer.nix { })
          (cp ./_files/wake-desktob.nix { })
        ];
      };
    };

}
