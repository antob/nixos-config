{
  flake.modules.nixos.time =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        time.timeZone = "Europe/Stockholm";
      };
    };

}
