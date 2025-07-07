{ pkgs, ... }:

{
  services.fail2ban = {
    enable = true;
    # Ban IP after 5 failures
    maxretry = 3;
    ignoreIP = [
      "192.168.1.0/24"
    ];
    bantime = "24h";

    jails = {
      nginx-url-probe.settings = {
        enabled = true;
        filter = "nginx-url-probe";
        findtime = 600;
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
        '';
        backend = "auto"; # Do not forget to specify this if your jail uses a log file
      };

      nginx-botsearch.settings = {
        enabled = true;
        filter = "nginx-botsearch";
        findtime = 600;
        logpath = "/var/log/nginx/access.log";
        action = ''
          %(action_)s[blocktype=DROP]
        '';
        backend = "auto"; # Do not forget to specify this if your jail uses a log file
      };
    };
  };

  environment.etc = {
    # Defines a filter that detects URL probing by reading the Nginx access log
    "fail2ban/filter.d/nginx-url-probe.local".text = pkgs.lib.mkDefault (
      pkgs.lib.mkAfter ''
        [Definition]
        failregex = ^<HOST>.*(GET /(wp-|admin|boaform|phpmyadmin|\.env|\.git)|\.(dll|so|cfm|asp)|(\?|&)(=PHPB8B5F2A0-3C92-11d3-A3A9-4C7B08C10000|=PHPE9568F36-D428-11d2-A769-00AA001ACF42|=PHPE9568F35-D428-11d2-A769-00AA001ACF42|=PHPE9568F34-D428-11d2-A769-00AA001ACF42)|\\x[0-9a-zA-Z]{2})
      ''
    );
  };
}
