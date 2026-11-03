{
  flake.modules.nixos.hyllan =
    _:

    let
      subdomain = "atuin";
      port = 8888;
    in
    {
      services = {
        atuin = {
          enable = true;
          inherit port;
          openRegistration = true;
          database = {
            createLocally = true;
            uri = "postgresql:///atuin?host=/run/postgresql";
          };
        };

        caddy.antobProxies."${subdomain}" = {
          hostName = "127.0.0.1";
          inherit port;
        };
      };
    };
}
