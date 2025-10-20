{
  lib,
  ...
}:

with lib;
{
  options.antob.system.info = with types; {
    desktop = mkOpt bool false "Enable if the host machine is a desktop.";
    laptop = mkOpt bool false "Enable if the host machine is a laptop.";
  };
}
