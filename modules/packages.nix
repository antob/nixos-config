{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      packages = import ../pkgs { inherit pkgs; };
      formatter = pkgs.nixfmt-tree;
    };
}
