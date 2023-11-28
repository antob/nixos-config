{ channels, ... }:

final: prev: {
  yubikey-touch-detector = prev.yubikey-touch-detector.overrideAttrs (oldAttrs: {
    version = "a241bcf";

    src = prev.fetchFromGitHub {
      owner = "maximbaz";
      repo = "yubikey-touch-detector";
      rev = "a241bcf70545821b89e9d5cc761e993a617aeae3";
      sha256 = "sha256-Zs+Fb+r07YLtKhcBZ5MzR6Lf12V2WyzSbH/2CMR1Dck=";
    };
  });
}
