{ pkgs, ... }:

pkgs.writeShellScriptBin "external-ip" ''
  # Script name: external-ip
  # Description: Show external IP address.
  # Dependencies: dig
  # Contributors: Tobias Lindholm

  ip=`${pkgs.dig}/bin/dig +short myip.opendns.com @resolver1.opendns.com 2>/dev/null`
  if [ $? -ne 0 ]; then
      echo "{\"text\": \" \", \"tooltip\": \"No connection\", \"class\": \"disconnected\"}"
  else
      echo "{\"text\": \" \", \"tooltip\": \"External IP is $ip\", \"class\": \"connected\"}"
  fi
''
