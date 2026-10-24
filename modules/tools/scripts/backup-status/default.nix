{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "backup-status";
  runtimeInputs = with pkgs; [
    curl
    jq
    restic
  ];
  text = builtins.readFile ./backup-status.sh;
}
