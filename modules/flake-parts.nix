{ inputs, lib, config, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  # flake.modules entries carry no module key, so importing an aspect from two places
  # (a preset and a host, or as another aspect's dependency) would declare its options twice.
  options.aspects = lib.mkOption {
    type = lib.types.raw;
    readOnly = true;
    description = "flake.modules wrapped with a stable key so repeated imports are deduplicated.";
    default = lib.mapAttrs (
      class: lib.mapAttrs (
        name: module: {
          key = "aspect/${class}/${name}";
          imports = [ module ];
        }
      )
    ) config.flake.modules;
  };

  config.systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
}
