{ options, config, pkgs, lib, inputs, ... }:

with lib;
let

  mkOpt = type: default: description:
    mkOption { inherit type default description; };

  cfg = config.host.security.gpg;

  pinentry = if config.gtk.enable then {
    package = pkgs.pinentry-gnome;
    name = "gnome3";
  } else {
    package = pkgs.pinentry-curses;
    name = "curses";
  };

  reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
    ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
  '';

in {

  options.host.security.gpg = with types; {
    enable = mkEnableOption "Whether or not to enable GPG.";
  };

  config = mkIf cfg.enable {
    # services.pcscd.enable = true;
    # services.udev.packages = with pkgs; [ yubikey-personalization ];

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      enableScDaemon = true;
      defaultCacheTtl = 60;
      maxCacheTtl = 120;
      # sshKeys = [ "149F16412997785363112F3DBD713BC91D51B831" ];
      pinentryFlavor = pinentry.name;
      enableExtraSocket = true;
    };

    home.packages = with pkgs; [
      pinentry.package
      # cryptsetup
      # paperkey
      # gnupg
      reload-yubikey
    ];

    # programs = { ssh.startAgent = false; };

    programs = let
      fixGpg = ''
        gpgconf --launch gpg-agent
      '';
    in {
      # Start gpg-agent if it's not running or tunneled in
      # SSH does not start it automatically, so this is needed to avoid having to use a gpg command at startup
      # https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
      bash.profileExtra = fixGpg;
      fish.loginShellInit = fixGpg;
      zsh.loginExtra = fixGpg;

      gpg = {
        enable = true;
        scdaemonSettings = { disable-ccid = true; };
        settings = { trust-model = "tofu+pgp"; };
        # publicKeys = [{
        #   source = ../../pgp.asc;
        #   trust = 5;
        # }];
      };
    };
    home.persistence = {
      "/persist/home/${config.host.user.name}".directories = [ ".gnupg" ];
    };
  };
}
