{ options, lib, ... }:

with lib;
with lib.antob;
{
  options.antob.monitoring = with types; {
    emailFrom = mkOpt str "home@antob.se" "Monitoring email from address.";
    emailTo = mkOpt str "tob@antob.se" "Monitoring email to address.";
  };
}
