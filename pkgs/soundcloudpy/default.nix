{
  pkgs,
  lib,
  fetchFromGitHub,
}:

pkgs.python313Packages.buildPythonPackage rec {
  pname = "SoundcloudPy";
  version = "0.1.4";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "music-assistant";
    repo = "SoundcloudPy";
    tag = version;
    hash = "sha256-NuL6VIAssvYiGWqioMtf3Brw/G8Vt2P4/57l3k3db9g=";
  };

  build-system = [ pkgs.python313Packages.setuptools ];

  dependencies = with pkgs.python313Packages; [
    aiohttp
    mashumaro
  ];

  meta = with lib; {
    description = "Async client for connecting to the Soundcloud API.";
    homepage = "https://github.com/music-assistant/SoundcloudPy";
    license = licenses.asl20;
  };
}
