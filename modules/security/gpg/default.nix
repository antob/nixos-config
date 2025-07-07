{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.security.gpg;

  pinentry =
    if config.antob.desktop.gnome.enable then
      {
        path = "${pkgs.pinentry-gnome3}/bin/pinentry-gnome3";
        name = "gnome3";
      }
    else if config.antob.desktop.hyprland.enable then
      {
        path = "${pkgs.pinentry-tofi}/bin/pinentry-tofi";
        name = null;
      }
    else
      {
        path = "${pkgs.pinentry-dmenu}/bin/pinentry-dmenu";
        name = null;
      };

in
{
  options.antob.security.gpg = with types; {
    enable = mkEnableOption "Whether or not to enable GPG.";
  };

  config = mkIf cfg.enable {

    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
      cryptsetup
      paperkey
      gnupg
    ];

    antob.home.extraOptions = {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableScDaemon = true;
        defaultCacheTtl = 60;
        maxCacheTtl = 120;
        # sshKeys = [ "149F16412997785363112F3DBD713BC91D51B831" ];
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
            scdaemonSettings = {
              disable-ccid = true;
            };
            settings = {
              trust-model = "tofu+pgp";
            };
            # publicKeys = [{
            #   source = ../../pgp.asc;
            #   trust = 5;
            # }];

            # Fixes scdaemon problem until next unstable release.
            # See https://github.com/NixOS/nixpkgs/pull/308884
            package = pkgs.gnupg.override {
              pcsclite = pkgs.pcsclite.overrideAttrs (old: {
                postPatch =
                  old.postPatch
                  + (lib.optionalString
                    (!(lib.strings.hasInfix ''--replace-fail "libpcsclite_real.so.1"'' old.postPatch))
                    ''
                      substituteInPlace src/libredirect.c src/spy/libpcscspy.c \
                        --replace-fail "libpcsclite_real.so.1" "$lib/lib/libpcsclite_real.so.1"
                    ''
                  );
              });
            };
          };
        };
    };

    antob.persistence.safe.home.directories = [ ".gnupg" ];
  };
}
