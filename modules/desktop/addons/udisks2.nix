{
  flake.modules.nixos.udisks2 =
    {
      config,
      lib,
      ...
    }:

    {
      config = {
        services.udisks2.enable = true;
      };
    };

}
