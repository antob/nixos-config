{
  flake.modules.nixos.time =
    {
      config,
      lib,
      ...
    }:

    {
      config = {
        time.timeZone = "Europe/Stockholm";
      };
    };

}
