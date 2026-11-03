{ inputs, config, ... }:
let
  importChannel =
    input: final:
    import input {
      inherit (final.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: true;
        allowUnfree = true;
      };
    };
in
{
  flake.overlays = {
    # Aliases 'pkgs.inputs.${flake}' to that input's packages (or legacyPackages) for this system
    flake-inputs = final: _: {
      inputs = builtins.mapAttrs (
        _: flake:
        let
          inherit (final.stdenv.hostPlatform) system;
          legacyPackages = (flake.legacyPackages or { }).${system} or { };
          packages = (flake.packages or { }).${system} or { };
        in
        if legacyPackages != { } then legacyPackages else packages
      ) inputs;
    };

    stable = final: _: { stable = importChannel inputs.nixpkgs-stable final; };
    next = final: _: { next = importChannel inputs.nixpkgs-next final; };
    prev = final: _: { prev = importChannel inputs.nixpkgs-prev final; };

    additions = final: _: import ../pkgs { pkgs = final; };

    modifications = final: prev: {
      # TODO: Temporary workaround until nixpkgs signs these out-of-tree modules.
      # The kernel module aggregator now expects a kmodigest `.ko.cer` next to
      # every external module, but packages that install `.ko` files without
      # `modules_install` never produce one.
      linuxPackages = prev.linuxPackages.extend final.signExternalKernelModules;
      linuxPackages_latest = prev.linuxPackages_latest.extend final.signExternalKernelModules;

      signExternalKernelModules =
        _: kprev:
        let
          signModules =
            drv:
            drv.overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.buildPackages.kmodigest ];
              postInstall = (old.postInstall or "") + ''
                find $out/lib/modules -name '*.ko' -exec kmodigest {} \;
              '';
            });
        in
        {
          ddcci-driver = signModules kprev.ddcci-driver;
          framework-laptop-kmod = signModules kprev.framework-laptop-kmod;
          xpad-noone = signModules kprev.xpad-noone;
        };
    };
  };

  flake.modules.nixos.overlays = {
    nixpkgs.overlays = builtins.attrValues config.flake.overlays;
  };
}
