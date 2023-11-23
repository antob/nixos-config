{ options, config, pkgs, lib, inputs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.security.gpg;

  colors = config.antob.color-scheme.colors;

  reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
    ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
  '';

  pinentry =
    if config.antob.desktop.gnome.enable then {
      path = "${pkgs.pinentry-gnome}/bin/pinentry-gnome";
      name = "gnome3";
    } else if config.antob.desktop.hyprland.enable then {
      path = "${pkgs.antob.pinentry-tofi}/bin/pinentry-tofi";
      name = null;
    } else {
      path = "${pkgs.antob.pinentry-dmenu}/bin/pinentry-dmenu";
      name = null;
    };

in
{
  options.antob.security.gpg = with types; {
    enable = mkEnableOption "Whether or not to enable GPG.";
  };

  config = mkIf cfg.enable {

    services.pcscd.enable = true;
    services.udev.packages = with pkgs; [ yubikey-personalization ];

    environment.systemPackages = with pkgs; [
      cryptsetup
      paperkey
      gnupg
      paperkey
      reload-yubikey
    ];

    antob.home.extraOptions = {
      systemd.user.services.gpg-agent.Service.Environment = [ "BEMENU_OPTS='-H 30 --fn \"SFNS Display Bold 9\" --hb \"#${colors.base06}\" --hf \"#${colors.base13}\" --nf \"#${colors.base07}\" --nb \"#${colors.base10}\" --fb \"#${colors.base10}\" --ff \"#${colors.base07}\" --tb \"#${colors.base10}\" --tf \"#${colors.base07}\"'" ];

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableScDaemon = true;
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
        # sshKeys = [ "149F16412997785363112F3DBD713BC91D51B831" ];
        pinentryFlavor = pinentry.name;
        enableExtraSocket = true;
        extraConfig = ''
          pinentry-program ${pinentry.path}
        '';
      };

      programs =
        let
          fixGpg = ''
            gpgconf --launch gpg-agent
          '';
        in
        {
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
    };

    antob.persistence.safe.home.directories =
      mkIf config.antob.persistence.enable [ ".gnupg" ];
  };
}
