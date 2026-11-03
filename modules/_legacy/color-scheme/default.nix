{
  lib,
  ...
}:

with lib;
let
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
      type = with types; attrsOf (coercedTo str (removePrefix "#") hexColorType);
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
    antob.color-scheme = {
      colors = import ./tokyonight-night.nix // {
        base10 = "#282c34"; # Alt Black
        base11 = "#e5c07b"; # Alt Yellow
        base12 = "#353b45"; # Alt Grey
        base13 = "#191919"; # Dark Grey
        base14 = "#1b1f27"; # Alt Black 2
      };
    };
  };
}
