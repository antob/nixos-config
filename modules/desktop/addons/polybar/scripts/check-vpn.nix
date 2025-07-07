{ pkgs, ... }:

pkgs.writeShellScriptBin "check-vpn" ''
  # Script name: check-vpn
  # Description: Check if there is an active VPN connection.
  # Dependencies: ifconfig
  # Contributors: Tobias Lindholm

  tun=$(${pkgs.unixtools.ifconfig}/bin/ifconfig tun0 2>&1 | ${pkgs.gnugrep}/bin/grep '00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00')
  ppp=$(${pkgs.unixtools.ifconfig}/bin/ifconfig ppp0 2>&1 | ${pkgs.gnugrep}/bin/grep 'ppp0: flags')

  [ -z "''${tun}" -a -z "''${ppp}" ] && echo "" && exit

  echo " VPN "
''
