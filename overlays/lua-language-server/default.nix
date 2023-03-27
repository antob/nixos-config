{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) lua-language-server;
}
