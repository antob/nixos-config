{ pkgs, lib, stdenv, ... }:

pkgs.buildGoModule rec {
  pname = "devbox";
  version = "custom";

  src = pkgs.fetchFromGitHub {
    owner = "jetpack-io";
    repo = pname;
    rev = "8dc37f37f7336b14b2a16f0bdb13f24d15b577ac";
    hash = "sha256-ghKPDkBDG7k4oQ1jdFKF2k8WQAHjCMnnhgu8IOkXulU=";
  };

  ldflags = [
    "-s"
    "-w"
    "-X go.jetpack.io/devbox/internal/build.Version=${version}"
  ];

  # integration tests want file system access
  doCheck = false;

  vendorHash = "sha256-Ct1hftgMYAF8DPdnYTB1QQYD0HGC4wifIbMX+TrgDdk=";

  nativeBuildInputs = [ pkgs.installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd devbox \
      --bash <($out/bin/devbox completion bash) \
      --fish <($out/bin/devbox completion fish) \
      --zsh <($out/bin/devbox completion zsh)
  '';

  meta = with lib; {
    description = "Instant, easy, predictable shells and containers.";
    homepage = "https://www.jetpack.io/devbox";
    license = licenses.asl20;
    maintainers = with maintainers; [ urandom ];
  };
}
