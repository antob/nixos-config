{ pkgs, ... }:

pkgs.writeShellScriptBin "disk-usage" ''
  # Script name: disk-usage
  # Description: Print disk usage of / /home/tob and total btrfs disk.
  # Dependencies: btrfs, awk, grep, df, xargs
  # Contributors: Tobias Lindholm

  root_avail=''$(${pkgs.coreutils}/bin/df -h / | ${pkgs.gnugrep}/bin/grep none | ${pkgs.gawk}/bin/awk '{printf $5}' | ${pkgs.coreutils}/bin/tr -d '%')
  home_avail=''$(${pkgs.coreutils}/bin/df -h /home/tob | ${pkgs.gnugrep}/bin/grep none | ${pkgs.gawk}/bin/awk '{printf $5}' | ${pkgs.coreutils}/bin/tr -d '%')
  # disk_avail=''$(sudo ${pkgs.btrfs-progs}/bin/btrfs fi show --raw | ${pkgs.gnugrep}/bin/grep devid | ${pkgs.gawk}/bin/awk '{print ($6/$4)*100}' | ${pkgs.findutils}/bin/xargs ${pkgs.coreutils}/bin/printf "%.0f")

  # echo "''${disk_avail} / ''${root_avail} / ''${home_avail}"
  echo "''${root_avail} / ''${home_avail}"
''
