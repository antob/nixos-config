{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.rustup;
in
{
  options.antob.tools.rustup = with types; {
    enable = mkBoolOpt false "Whether or not to enable rustup.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustup
      wasm-pack
      cargo-generate
      nodejs
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
  };
}
