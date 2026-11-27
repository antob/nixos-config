{ inputs, ... }:
{
  flake.modules.nixos.hyllan =
    { config, ... }:

    let
      subdomain = "roost";
      port = 8787;
      inherit (config.sops) secrets;
    in
    {
      imports = [ inputs.roost.nixosModules.default ];

      antob.agent-access.logUnits = [
        "roost"
      ];

      services = {
        roost = {
          enable = true;
          baseUrl = "https://${subdomain}.antob.net";
          dataDir = "/mnt/tank/services/roost";
          # Never rotate casually: a new key drops every push subscription.
          vapidKeyFile = secrets.roost_vapid_key.path;
          environmentFile = secrets.roost_env.path;
        };

        caddy.antobProxies."${subdomain}" = {
          hostName = "127.0.0.1";
          inherit port;
        };
      };

      # Root-owned is fine: the key is passed as a systemd credential, the env file is read by systemd.
      sops.secrets = {
        roost_vapid_key = { };
        roost_env = { };
      };
    };
}
