{ pkgs, ... }:

pkgs.buildFHSEnv {
  name = "zed";
  targetPkgs =
    pkgs: with pkgs; [
      zed-editor
    ];
  runScript = "zed";
}
