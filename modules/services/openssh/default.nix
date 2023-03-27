{ options, config, pkgs, lib, systems, name, format, inputs, ... }:

with lib;
let
  cfg = config.antob.services.openssh;

  user = config.users.users.${config.antob.user.name};
  user-id = builtins.toString user.uid;

  default-key =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ==";

  other-hosts = lib.filterAttrs
    (key: host: key != name && (host.config.antob.user.name or null) != null)
    ((inputs.self.nixosConfigurations or { })
      // (inputs.self.darwinConfigurations or { }));

  other-hosts-config = lib.concatMapStringsSep "\n" (name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.antob.user.name;
      remote-user-id =
        builtins.toString remote.config.users.users.${remote-user-name}.uid;

      forward-gpg = optionalString (config.programs.gnupg.agent.enable
        && remote.config.programs.gnupg.agent.enable) ''
          RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
          RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
        '';

    in ''
      Host ${name}
        User ${remote-user-name}
        ForwardAgent yes
        Port ${builtins.toString cfg.port}
        ${forward-gpg}
    '') (builtins.attrNames other-hosts);
in {
  options.antob.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys =
      mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      passwordAuthentication = false;
      permitRootLogin = if format == "install-iso" then "yes" else "no";

      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [ 22 cfg.port ];
    };

    programs.ssh.extraConfig = ''
      Host *
        HostKeyAlgorithms +ssh-rsa

      ${other-hosts-config}
    '';

    antob.user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
