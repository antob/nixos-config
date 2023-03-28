{ channels, ... }:

final: prev: {
  dmenu = prev.dmenu.overrideAttrs (oldAttrs: {
    src = prev.fetchFromGitHub {
      owner = "antob";
      repo = "dmenu";
      rev = "11d468b";
      sha256 = "sha256-NLDwvaeyUqcFeGfMDdEIhSB1f9/MmlyYjaxbSrAAYPc=";
    };
  });
}
