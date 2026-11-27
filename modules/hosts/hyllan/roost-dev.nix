{
  # Development instance of roost, started by hand on desktob (see desktob/roost-dev.nix).
  flake.modules.nixos.hyllan = _: {
    services.caddy.antobProxies."roost-dev" = {
      hostName = "10.64.1.6";
      port = 8787;
    };
  };
}
