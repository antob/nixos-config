{ channels, ... }:

final: prev:

{ inherit (channels.nixpkgs-stable) networkmanager-l2tp; }
