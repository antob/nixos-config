{ config, ... }:

{
  # Necessary for user-specific impermanence
  programs.fuse.userAllowOther = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"

    ];
    files = [
      "/etc/machine-id"
      "/ssh/ssh_host_rsa_key"
      "/ssh/ssh_host_rsa_key.pub"
      "/ssh/ssh_host_ed25519_key"
      "/ssh/ssh_host_ed25519_key.pub"
    ];
    users.${config.antob.user.name} = {
      directories = [
        "Projects"
      ];
      files = [
        ".zsh_history"
      ];
    };
  };
}
