{ channels, inputs, ... }:

final: prev: {
  nvchad = inputs.nvchad4nix.packages."${prev.system}".nvchad;
}
