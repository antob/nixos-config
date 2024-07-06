{ pkgs, lib, stdenv, ... }:

pkgs.buildFHSUserEnv {
  name = "zed";
  targetPkgs = pkgs:
    with pkgs; [
      zed-editor
    ];
  runScript = "zed";
}
