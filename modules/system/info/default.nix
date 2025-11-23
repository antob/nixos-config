{
  lib,
  ...
}:

with lib;
{
  options.antob.system.info = with types; {
    laptop = mkBoolOpt false "The system is a laptop.";
  };
}
