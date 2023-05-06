{ channels, ... }:

final: prev: {
  yubikey-touch-detector = prev.yubikey-touch-detector.overrideAttrs (oldAttrs: {
    postInstall = "";
  });
}
