{ inputs, ... }:
{
  flake.nixosConfigurations.rpi4-installer = inputs.nixos-raspberrypi.lib.nixosInstaller {
    system = "aarch64-linux";
    modules = [
      {
        imports = with inputs.nixos-raspberrypi.nixosModules; [
          raspberry-pi-4.base
        ];

        sdImage.compressImage = false;
        boot.zfs.forceImportRoot = false;
        services.openssh = {
          enable = true;
          settings.PermitRootLogin = "yes";
        };
        users.users.root.openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIB2/+00zZtto7zwPegLiD9S+DivUiGSPL3BhoZI1pwqLhuKItvxbMnX+kUWfCyMcN20N7uYOZP4iCmyKIeUkQ1FgTqnRtDxignmni5xF31/h7gNf/POPWxagBFWzYYxxCknWzYFiupLN0VTobq4ZQ+1t2i/U2/j9nuElUV1/GjmlW/yjSBN647T8oB4mvVRJ2eIkd/pxL+dRCeX2N1UjZqoS7MZvgUNsS9/30gjau1+n8Fl4sERQr9tq8qz24HsWhdzmNCdQSnXbAe6hczQeOlwbCFLYcPW5ygtG+GYB7FWEbaeDOpfcXjcBdxhQXLL8QN5Nml1NzQj3OTYrihwTlHHeeGZXWFKa5OKfzX3zIXNkWfDlfThiMCGLt5S9A51C5m8SVRrQ9TC9ptwvNwOIqry4fyURtbSWUHV9r6SzYzifYwHn50OJ62Wr9ySWwRgh6xRD/8xtKI4y0hQGryoV9TxFtL1SvbbZybLgW0WSFPrCtk9dsAjCos1Wxpf3pqxJTH2HEYx3o03I7fYIxav6ZppNNLV6b5Hd6z2ExJoaax2A+YEds8pSJD+0L6ci9RU/AgaI1wlkLHOnkohTp7ZAK5KWEXJ6K4mXRH4sDvXNDDjYj1TvLZY8NlpHnwRzFkll2SzshegYkG3YoLeoAn4GW/0AkC0iX0ccirqRwN0i+UQ=="
        ];
      }
    ];
  };
}
