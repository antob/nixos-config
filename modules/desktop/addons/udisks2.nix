{
  flake.modules.nixos.udisks2 =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        services.udisks2.enable = true;
      };
    };

}
