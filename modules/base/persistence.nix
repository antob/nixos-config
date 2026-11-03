{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.base =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      options.antob.persistence = with types; {
        path = mkOpt str "/persist" "Path to persistent folder.";
        files = mkOpt (listOf anything) [ ] "A list of files to be stored in persistent storage.";
        directories =
          mkOpt (listOf anything) [ ]
            "A list of directories to be stored in persistent storage.";
        home = {
          files =
            mkOpt (listOf anything) [ ]
              "A list of files in user home to be stored in persistant storage.";
          directories =
            mkOpt (listOf anything) [ ]
              "A list of directories in user home to be stored in persistant storage.";
        };
        safe = {
          files =
            mkOpt (listOf anything) [ ]
              "A list of files to be stored in persistent storage and backed up offsite.";
          directories =
            mkOpt (listOf anything) [ ]
              "A list of directories to be stored in persistent storage and backed up offsite.";
          home = {
            files =
              mkOpt (listOf anything) [ ]
                "A list of files in user home to be stored in persistant storage and backed up offsite.";
            directories =
              mkOpt (listOf anything) [ ]
                "A list of directories in user home to be stored in persistant storage and backed up offsite.";
          };
        };
      };
    };
}
