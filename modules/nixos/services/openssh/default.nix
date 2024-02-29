{ options, config, pkgs, lib, format ? "", inputs ? { }, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.services.openssh;

  default-key =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ==";
in
{
  options.antob.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys =
      mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = if format == "install-iso" then "yes" else "no";
      };

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [ 22 cfg.port ];
    };

    networking.firewall.allowedTCPPorts = [ 22 cfg.port ];

    antob = {
      home.extraOptions.programs.ssh = {
        enable = true;
        forwardAgent = true;
        serverAliveInterval = 5;
        serverAliveCountMax = 1;
        controlMaster = "auto";
        controlPersist = "180";
        extraOptionOverrides = {
          Ciphers = "aes128-gcm@openssh.com,aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr";
        };
        extraConfig = ''
          HostKeyAlgorithms +ssh-rsa
          PubkeyAcceptedKeyTypes +ssh-rsa
          User ${config.antob.user.name}
        '';
        matchBlocks = {
          hyllan.hostname = "hyllan.lan";
          pikvm = {
            hostname = "pikvm.lan";
            user = "root";
          };
          bender.hostname = "192.168.1.20";
          hyllan-old = {
            hostname = "192.168.1.231";
            user = "tobias";
            port = 2212;
          };
          locals = {
            host = "192.168.* *.lan laptob*";
            extraOptions = {
              UserKnownHostsFile = "/dev/null";
              StrictHostKeyChecking = "no";
              LogLevel = "ERROR";
            };
          };
        };
        includes = [ "hosts" ];
      };

      persistence.home.files = [ ".ssh/known_hosts" ];
      user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
  };
}
