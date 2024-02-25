{ pkgs, lib, ... }:

with lib;
{

  antob = {
    virtualisation.podman.enable = true;
    virtualisation.docker.enable = mkForce false;
  };


  virtualisation.oci-containers = {
    backend = "podman";
  };
}
