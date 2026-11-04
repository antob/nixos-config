{
  flake.modules.nixos.rustup =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      config = {
        environment.systemPackages = with pkgs; [
          rustup
          wasm-pack
          cargo-generate
          nodejs
          bacon
          lldb
          llvmPackages.bintools
          openssl
          gcc
          pkg-config
        ];

        antob.system.env = {
          CARGO_HOME = "$XDG_DATA_HOME/cargo";
          RUSTUP_HOME = "$XDG_DATA_HOME/rustup";
        };

        antob.persistence.home.directories = [
          ".local/share/rustup"
          ".local/share/cargo"
        ];
      };
    };

}
