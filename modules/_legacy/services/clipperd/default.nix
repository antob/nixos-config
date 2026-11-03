{
  config,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.services.clipperd;
  secrets = config.sops.secrets;
  userName = config.antob.user.name;
in
{
  options.antob.services.clipperd = with types; {
    enable = mkEnableOption "Whether or not to enable clipperd.";
    bindIp = mkOpt (nullOr str) null "The IP address to bind the clipperd service to.";
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.bindIp != null;
        message = "antob.services.clipperd.bindIp must be set.";
      }
    ];

    antob.home.extraOptions = {
      imports = [ inputs.clipperd.homeManagerModules.default ];
      services.clipperd = {
        enable = true;
      };

      xdg.configFile."clipperd/config.toml".text = /* toml */ ''
        token_file = "${secrets.clipperd_api_token.path}"
        port = 7171
        cert_pem = """
        -----BEGIN CERTIFICATE-----
        MIIBhDCCASqgAwIBAgIUZQ3yY7QcNXjYmyhH+RL/t7fyrU8wCgYIKoZIzj0EAwIw
        KTEUMBIGA1UEAwwLQ2xpcHBlcmQgQ0ExETAPBgNVBAoMCENsaXBwZXJkMB4XDTI2
        MDkwNDA2NTYyOFoXDTI4MDkwMzA2NTYyOFowGzEZMBcGA1UEAwwQbGFwdG9iLmFu
        dG9iLm5ldDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABBDysX1bn8eqgX6wugfS
        ZzlC4Fy9k5kx3/9hj0ZR2BtoOfuBoynWPud3VVEKPxehX1d/PbclTHnaovulJbyJ
        lMCjPjA8MDoGA1UdEQQzMDGCEGxhcHRvYi5hbnRvYi5uZXSCEWRlc2t0b2IuYW50
        b2IubmV0hwR/AAABhwQKQAEHMAoGCCqGSM49BAMCA0gAMEUCIECCChmcZUiyBb6J
        yzT9Le18bsGTfpuBzswm7FKn21cfAiEA+L6PHVe5h+ZCDYumOASSJf2v3ZWGU8BA
        kq1vcemqwdU=
        -----END CERTIFICATE-----
        """
        key_pem_file = "${secrets.clipperd_cert_key.path}"
        ca_cert_pem = """
        -----BEGIN CERTIFICATE-----
        MIIBhTCCASygAwIBAgIUbgthDCnnPmx8iaj974GXRo3bh04wCgYIKoZIzj0EAwIw
        KTEUMBIGA1UEAwwLQ2xpcHBlcmQgQ0ExETAPBgNVBAoMCENsaXBwZXJkMB4XDTI0
        MDEwMTAwMDAwMFoXDTM1MDEwMTAwMDAwMFowKTEUMBIGA1UEAwwLQ2xpcHBlcmQg
        Q0ExETAPBgNVBAoMCENsaXBwZXJkMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
        FkeDdK1EzzdkuNOZ2afOr83yTHcNt5xfaoYSzl9/k5nw2lBzM83EvsE7XW5aGIek
        e/7s/ZZPyTSJhzjjYP1oQqMyMDAwHQYDVR0OBBYEFAwy0hL0XTQ2Kq8IE+kcH6+t
        Znn+MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDRwAwRAIgXudHiJ7SvnET
        PZ+mW0ny13d7IVRZn+HqsI3PtVt5Xq0CIHiv8p9u0um1ffoUjMGUn1ceQ5j26r4o
        x1yo3/CyjlLI
        -----END CERTIFICATE-----
        """
        bind_ip = "${cfg.bindIp}"
        cert_names = [
            "laptob.antob.net",
            "desktob.antob.net",
        ]
      '';
    };

    networking.firewall.allowedTCPPorts = [ 7171 ];

    sops.secrets = {
      clipperd_cert_key = {
        sopsFile = ../../../hosts/common/secrets.yaml;
        owner = userName;
      };
      clipperd_api_token = {
        sopsFile = ../../../hosts/common/secrets.yaml;
        owner = userName;
      };
    };
  };
}
