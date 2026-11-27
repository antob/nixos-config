{
  flake.modules.nixos.desktob = _: {
    # Hand-started dev server, plain HTTP: only reachable from the hyllan proxy over wg0.
    networking.firewall.extraInputRules = ''
      iifname "wg0" ip saddr { 10.64.1.2 } tcp dport 8787 accept
    '';
  };
}
