{
  inputs,
}:
{
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.stdenv.hostPlatform.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.stdenv.hostPlatform.system}'
  flake-inputs = final: _: {
    inputs = builtins.mapAttrs (
      _: flake:
      let
        system = final.stdenv.hostPlatform.system;
        legacyPackages = (flake.legacyPackages or { }).${system} or { };
        packages = (flake.packages or { }).${system} or { };
      in
      if legacyPackages != { } then legacyPackages else packages
    ) inputs;
  };

  stable = final: _: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfreePredicate = (pkg: true);
        allowUnfree = true;
      };
    };
  };

  pkgs-next = final: _: {
    pkgs-next = import inputs.nixpkgs-next {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfreePredicate = (pkg: true);
        allowUnfree = true;
      };
    };
  };

  pkgs-prev = final: _: {
    pkgs-prev = import inputs.nixpkgs-prev {
      system = final.stdenv.hostPlatform.system;
      config = {
        allowUnfreePredicate = (pkg: true);
        allowUnfree = true;
      };
    };
  };

  # Adds my custom packages
  additions = final: prev: import ../pkgs { pkgs = final; };

  # Modifies existing packages
  modifications = final: prev: {
    # ddcci-driver fails to build on newer kernels (e.g. 7.2.2) with GCC 15:
    # it calls kernel string functions without including <linux/string.h>, and
    # kernel 7.x removed strncpy() entirely in favor of strscpy().
    linuxPackages_latest = prev.linuxPackages_latest.extend (lfinal: lprev: {
      ddcci-driver = lprev.ddcci-driver.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          ./patches/ddcci-driver-linux-string-h.patch
        ];
      });
    });

    dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
      src = prev.fetchFromGitHub {
        owner = "antob";
        repo = "dmenu";
        rev = "cd3f248";
        sha256 = "sha256-OHvRuex2k72FJiVaMZkcmbpoKIgqpZzxrAImgg8XVeI=";
      };
    });
  };
}
