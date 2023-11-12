{ options, config, lib, ... }:

with lib;
let
  cfg = config.antob.color-scheme;
  hexColorType = mkOptionType {
    name = "hex-color";
    descriptionClass = "noun";
    description = "RGB color in hex format";
    check = x: isString x && !(hasPrefix "#" x);
  };
in
{
  options.antob.color-scheme = {
    colors = mkOption {
      type = with types; attrsOf (
        coercedTo str (removePrefix "#") hexColorType
      );
      default = { };
      example = literalExpression ''
        {
          base00 = "#1e2127";
          base01 = "#be5046";
          base02 = "#98c379";
          base03 = "#d19a66";
          base04 = "#61afef";
          base05 = "#e06c75";
          base06 = "#56b6c2";
          base07 = "#abb2bf";
          base08 = "#5c6370";
          base09 = "#be5046";
          base0A = "#98c379";
          base0B = "#d19a66";
          base0C = "#61afef";
          base0D = "#e06c75";
          base0E = "#56b6c2";
          base0F = "#ffffff";
        }
      '';
    };
  };

  config = {
    antob.color-scheme.colors = {
      base00 = "#1e2127"; # Black
      base01 = "#be5046"; # Red
      base02 = "#98c379"; # Green
      base03 = "#d19a66"; # Yellow
      base04 = "#61afef"; # Blue
      base05 = "#e06c75"; # Mangenta
      base06 = "#56b6c2"; # Cyan
      # base07 = "#abb2bf"; # White
      base07 = "#ebdbb2"; # White
      base08 = "#5c6370"; # Grey
      base09 = "#be5046"; # Bright Red
      base0A = "#98c379"; # Bright Green
      base0B = "#d19a66"; # Bright Yellow
      base0C = "#61afef"; # Bright Blue
      base0D = "#e06c75"; # Bright Mangenta
      base0E = "#56b6c2"; # Bright Cyan
      base0F = "#ffffff"; # Bright White

      base10 = "#282c34"; # Alt Black
      base11 = "#e5c07b"; # Alt Yellow
      base12 = "#353b45"; # Alt Grey
    };
  };
}
