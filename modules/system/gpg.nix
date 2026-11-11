{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.gpg =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        home-manager.sharedModules = [ homeManager.gpg ];

        services.pcscd.enable = true;

        environment.systemPackages = with pkgs; [
          cryptsetup
          paperkey
          gnupg
        ];

        antob.persistence.safe.home.directories = [
          {
            directory = ".gnupg";
            mode = "0700";
          }
        ];
      };
    };

  flake.modules.homeManager.gpg =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      pinentry =
        if osConfig.services.desktopManager.gnome.enable then
          {
            path = "${pkgs.pinentry-gnome3}/bin/pinentry-gnome3";
            name = "gnome3";
          }
        else
          {
            path = "${pkgs.pinentry-rofi}/bin/pinentry-rofi";
            name = null;
          };
    in
    {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableScDaemon = true;
        # scdaemon re-unlocks the card from this cache after a reset; per-use touch still applies
        defaultCacheTtl = 28800;
        maxCacheTtl = 86400;
        # sshKeys = [ "149F16412997785363112F3DBD713BC91D51B831" ];
        enableExtraSocket = true;
        extraConfig = ''
          pinentry-program ${pinentry.path}
        '';
        # The HM integration runs `updatestartuptty` in every shell, so a tty/ssh shell
        # would redirect SSH pinentry prompts to an invisible tty. Handled below instead.
        enableBashIntegration = false;
        enableZshIntegration = false;
        enableFishIntegration = false;
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

          # Only graphical shells may retarget the agent's startup env (used for SSH pinentry)
          bash.initExtra = ''
            GPG_TTY="$(tty)"
            export GPG_TTY
            [[ -n $WAYLAND_DISPLAY ]] && gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
          '';
          zsh.initContent = ''
            export GPG_TTY=$TTY
            [[ -n $WAYLAND_DISPLAY ]] && gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
          '';
          fish.interactiveShellInit = ''
            set -gx GPG_TTY (tty)
            set -q WAYLAND_DISPLAY; and gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
          '';

          gpg = {
            enable = true;
            scdaemonSettings = {
              disable-ccid = true;
              # Avoid OpenPGP<->PIV app switches that reset the card's PIN state
              disable-application = "piv";
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

}
