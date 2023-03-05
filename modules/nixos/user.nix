{ options, config, pkgs, lib, mkOpt, ... }:

with lib;

let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;

  cfg = config.host.user;

in {
  options.host.user = with types; {
    name = mkOpt str "short" "The name to use for the user account.";
    fullName = mkOpt str "Tobias Lindholm" "The full name of the user.";
    email = mkOpt str "tobias.lindholm@antob.se" "The email of the user.";
    initialPassword = mkOpt str "password"
      "The initial password to use when the user is first created.";
    autoLogin = mkBoolOpt false "Whether or not to autologin user.";
    extraGroups = mkOpt (listOf str) [ ] "Groups for the user to be assigned.";
    extraOptions = mkOpt attrs { }
      "Extra options passed to <option>users.users.<name></option>.";
  };

  config = {
    services.getty.autologinUser = mkIf cfg.autoLogin cfg.name;
    security.sudo.wheelNeedsPassword = false;

    users.users.${cfg.name} = {
      isNormalUser = true;

      inherit (cfg) name initialPassword;

      home = "/home/${cfg.name}";
      group = "users";

      shell = pkgs.zsh;

      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ=="
      ];

      extraGroups = [ "wheel" ] ++ cfg.extraGroups;
    } // cfg.extraOptions;
  };
}
