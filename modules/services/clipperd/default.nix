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
        MIIBizCCATCgAwIBAgIUcBk7Pu4YEsdSjcH4q0lxrlzFYH0wCgYIKoZIzj0EAwIw
        KTEUMBIGA1UEAwwLQ2xpcHBlcmQgQ0ExETAPBgNVBAoMCENsaXBwZXJkMB4XDTI2
        MDgzMTA4MjYwOVoXDTI4MDgzMDA4MjYwOVowHjEcMBoGA1UEAwwTbGFwdG9iLWZ3
        LmFudG9iLm5ldDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABNuRIX8Bpmofe79p
        3Q6hevj9otwHnP5is6HSNVAlnTHqghq9k0iqRnSHAhFVf4liNJRR/y5exTU+hNzw
        2adxNoOjQTA/MD0GA1UdEQQ2MDSCE2xhcHRvYi1mdy5hbnRvYi5uZXSCEWRlc2t0
        b2IuYW50b2IubmV0hwR/AAABhwQKQAEHMAoGCCqGSM49BAMCA0kAMEYCIQDasdjJ
        49np37xKcpbNwkfFBhlwm/9SjfRTV0Xv68j6ygIhAI2qGWP2o6VNJ+Zyy3NjgS7z
        pzSsagetagYwH4ZUDBIz
        -----END CERTIFICATE-----
        """
        key_pem_file = "${secrets.clipperd_cert_key.path}"
        ca_cert_pem = """
        -----BEGIN CERTIFICATE-----
        MIIBhjCCASygAwIBAgIUX2gyimk5Og/JklaRQLgwvYjeAaUwCgYIKoZIzj0EAwIw
        KTEUMBIGA1UEAwwLQ2xpcHBlcmQgQ0ExETAPBgNVBAoMCENsaXBwZXJkMB4XDTI0
        MDEwMTAwMDAwMFoXDTM1MDEwMTAwMDAwMFowKTEUMBIGA1UEAwwLQ2xpcHBlcmQg
        Q0ExETAPBgNVBAoMCENsaXBwZXJkMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE
        LJXnWuMCb8UpdiI7gINrmWOgiFKB4i6JiIfHRj3O6f8hGhCCS79WIzlTI0SlaNWE
        2HPE/+Jk4i/DcfftthiLCaMyMDAwHQYDVR0OBBYEFEuQAn98G2kHJP9IkH/LOm0+
        kFMuMA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSAAwRQIhANrpVtA6TsU4
        TkgrqbwQgNNlutKnnzNvw0tnInCIaE5cAiAjI87QriXMC43rOOshKUkyyZ1D5SVa
        2mP6nkH1w87HjQ==
        -----END CERTIFICATE-----
        """
        bind_ip = "${cfg.bindIp}"
        cert_names = [
            "laptob-fw.antob.net",
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
