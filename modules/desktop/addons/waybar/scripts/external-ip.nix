{ pkgs, ... }:

pkgs.writeShellScriptBin "external-ip" ''
  # Script name: external-ip
  # Description: Show external IP address.
  # Dependencies: curl
  # Contributors: Tobias Lindholm

  ip=`curl -s --connect-timeout 1 http://ifconfig.me`
  if [ $? -ne 0 ]; then
      echo "{\"text\": \" \", \"tooltip\": \"No connection\", \"class\": \"disconnected\"}"
  else
      echo "{\"text\": \" \", \"tooltip\": \"External IP is $ip\", \"class\": \"connected\"}"
  fi
''
