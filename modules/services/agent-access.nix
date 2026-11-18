{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  # Restricted `agent` login for AI agents; features grant it units, logs and commands through the options.
  flake.modules.nixos.agent-access =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.agent-access;
      user = "agent";
      home = "/var/lib/agent";
      withSuffix = unit: if hasInfix "." unit then unit else "${unit}.service";
      units = map withSuffix cfg.units;

      agentLogs = pkgs.writers.writePython3Bin "agent-logs" { flakeIgnore = [ "E501" ]; } (
        replaceStrings
          [ "@journalctl@" "@units@" ]
          [ "${config.systemd.package}/bin/journalctl" (builtins.toJSON (map withSuffix cfg.logUnits)) ]
          (builtins.readFile ./_files/agent-logs.py)
      );

      gitconfig = pkgs.writeText "agent-gitconfig" (
        generators.toGitINI {
          user = {
            name = "agent";
            email = "agent@${config.networking.hostName}";
          };
          safe.directory = cfg.gitSafeDirectories;
        }
      );

      nopasswd = command: {
        inherit command;
        options = [ "NOPASSWD" ];
      };
    in
    {
      options.antob.agent-access = with types; {
        authorizedKeys = mkOpt (listOf str) [
          (trim (builtins.readFile ./_files/agent-ssh-key.pub))
        ] "Public keys allowed to log in as the agent.";
        allowedFrom = mkOpt (listOf str) [ "10.64.1.0/24" ] "Source networks the agent may log in from.";
        units = mkOpt (listOf str) [ ] "Systemd units the agent may start, stop and restart.";
        logUnits =
          mkOpt (listOf str) [ ]
            "Systemd units whose journal the agent may read with `sudo agent-logs`.";
        sudoPackages = mkOpt (listOf package) [ ] "Packages whose main program the agent may run as root.";
        runAs =
          mkOpt (listOf str) [ ]
            "Sudo run-as specs (`user` or `user : group`) the agent may run any command as.";
        gitSafeDirectories =
          mkOpt (listOf str) [ ]
            "Git worktrees owned by someone else that the agent works in.";
        packages = mkOpt (listOf package) [ ] "Extra packages on the agent's PATH.";
      };

      config = {
        users = {
          users.${user} = {
            isSystemUser = true;
            group = user;
            description = "Restricted account for AI agents";
            inherit home;
            createHome = true;
            shell = pkgs.bashInteractive;
            packages = [
              agentLogs
              pkgs.git
            ]
            ++ cfg.sudoPackages
            ++ cfg.packages;
            # restrict: no pty, port, agent or X11 forwarding.
            openssh.authorizedKeys.keys = map (
              key: ''restrict,from="${concatStringsSep "," cfg.allowedFrom}" ${key}''
            ) cfg.authorizedKeys;
          };
          groups.${user} = { };
        };

        security.sudo.extraRules = [
          {
            users = [ user ];
            runAs = "root";
            # sudo matches the command's real parent directory, so `sudo <name>` (found via the
            # per-user profile) needs the profile path besides the store path.
            commands = concatMap (
              pkg:
              map nopasswd [
                (getExe pkg)
                "/etc/profiles/per-user/${user}/bin/${baseNameOf (getExe pkg)}"
              ]
            ) ([ agentLogs ] ++ cfg.sudoPackages);
          }
        ]
        ++ map (runAs: {
          users = [ user ];
          inherit runAs;
          commands = [ (nopasswd "ALL") ];
        }) cfg.runAs;

        security.polkit = mkIf (units != [ ]) {
          enable = true;
          extraConfig = ''
            polkit.addRule(function (action, subject) {
              if (action.id == "org.freedesktop.systemd1.manage-units" && subject.user == "${user}" &&
                  ${builtins.toJSON units}.indexOf(action.lookup("unit")) >= 0 &&
                  ["start", "stop", "restart", "try-restart"].indexOf(action.lookup("verb")) >= 0) {
                return polkit.Result.YES;
              }
            });
          '';
        };

        systemd.tmpfiles.rules = [ "L+ ${home}/.gitconfig - - - - ${gitconfig}" ];
      };
    };
}
