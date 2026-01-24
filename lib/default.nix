{
  lib,
  ...
}:
with lib;
lib.extend (
  final: prev: rec {
    mkOpt =
      type: default: description:
      mkOption { inherit type default description; };

    mkOpt' = type: default: mkOpt type default null;

    mkBoolOpt = mkOpt types.bool;

    mkBoolOpt' = mkOpt' types.bool;

    enabled = {
      enable = true;
    };

    disabled = {
      enable = false;
    };

    # use path relative to the root of the project
    relativeToRoot = lib.path.append ../.;
    scanPaths =
      path:
      map (f: (path + "/${f}")) (
        builtins.attrNames (
          lib.attrsets.filterAttrs (
            path: _type:
            (_type == "directory") # include directories
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path) # include .nix files
            )
          ) (builtins.readDir path)
        )
      );

    mkSslProxy = domain: target: {
      "${domain}".extraConfig = ''
        import deny_external_access

        tls {
          dns digitalocean {$DO_AUTH_TOKEN}
        }

        reverse_proxy ${target}
      '';
    };

    mkProxy = domain: target: {
      "${domain}".extraConfig = ''
        import deny_external_access

        tls internal
        reverse_proxy ${target}
      '';
    };

    ## Get files at a given path.
    ## Example Usage:
    ## ```nix
    ## getFiles ./something
    ## ```
    ## Result:
    ## ```nix
    ## [ "./something/a-file" ]
    ## ```
    #@ Path -> [Path]
    getFiles =
      path:
      let
        entries = safeReadDir path;
        filteredEntries = filterAttrs (name: kind: isFileKind kind) entries;
      in
      mapAttrsToList (name: kind: "${path}/${name}") filteredEntries;

    ## Safely read from a directory if it exists.
    ## Example Usage:
    ## ```nix
    ## safeReadDir ./some/path
    ## ```
    ## Result:
    ## ```nix
    ## { "my-file.txt" = "regular"; }
    ## ```
    #@ Path -> Attrs
    safeReadDir = path: if pathExists path then builtins.readDir path else { };

    ## Matchers for file kinds. These are often used with `readDir`.
    ## Example Usage:
    ## ```nix
    ## isFileKind "directory"
    ## ```
    ## Result:
    ## ```nix
    ## false
    ## ```
    #@ String -> Bool
    isFileKind = kind: kind == "regular";
    isSymlinkKind = kind: kind == "symlink";
    isDirectoryKind = kind: kind == "directory";
    isUnknownKind = kind: kind == "unknown";
  }
)
