{ pkgs, lib, stdenv, ... }:

pkgs.buildGoModule rec {
  pname = "devbox";
  version = "0.4.10-pre";

  src = pkgs.fetchFromGitHub {
    owner = "jetpack-io";
    repo = pname;
    rev = "1b0358cdee2a8c91ecc64fc0d1296b94fbb9c0d5";
    hash = "sha256-LZrXhLdkF9Q7iWIF8Z+u7qN6yLlRLq6xjOS9GzruKsk=";
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
