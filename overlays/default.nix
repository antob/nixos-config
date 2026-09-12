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
    # flashrom 1.8.0's cmocka tests are flaky on aarch64-linux,
    # breaking raspberrypi-eeprom for pi builds.
    # https://github.com/NixOS/nixpkgs/issues/558302
    flashrom = prev.flashrom.overrideAttrs (oldAttrs: {
      doCheck = false;
    });

    dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
      src = prev.fetchFromGitHub {
        owner = "antob";
        repo = "dmenu";
        rev = "cd3f248";
        sha256 = "sha256-OHvRuex2k72FJiVaMZkcmbpoKIgqpZzxrAImgg8XVeI=";
      };
    });

    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pyFinal: pyPrev: {
        # httpcore2 2.9.1's trio connection-pool-timeout tests race a 10ms
        # deadline against the pool cleaning itself up, which is flaky under
        # the load of a full nightly system build.
        httpcore2 = pyPrev.httpcore2.overridePythonAttrs (oldAttrs: {
          disabledTests = (oldAttrs.disabledTests or [ ]) ++ [
            "test_connection_pool_timeout_during_request"
            "test_connection_pool_timeout_during_response"
          ];
        });
      })
    ];
  };
}
