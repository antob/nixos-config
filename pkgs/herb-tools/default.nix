{ pkgs, ... }:

let
  src = ./.;
  packageLock = builtins.fromJSON (builtins.readFile (src + "/package-lock.json"));

  deps = builtins.filter (p: p != null) (
    map (name: if name == "" then null else builtins.getAttr name packageLock.packages) (
      builtins.attrNames packageLock.packages
    )
  );

  tarballs = map (
    p:
    if builtins.hasAttr "resolved" p && builtins.hasAttr "integrity" p then
      pkgs.fetchurl {
        url = p.resolved;
        hash = p.integrity;
      }
    else
      null
  ) deps;

  filteredTarballs = builtins.filter (x: x != null) tarballs;

  tarballsFile = pkgs.writeTextFile {
    name = "tarballs";
    text = builtins.concatStringsSep "\n" filteredTarballs;
  };

in
pkgs.stdenv.mkDerivation {
  inherit (packageLock) name version;
  inherit src;

  buildInputs = [ pkgs.nodejs ];

  dontCopyLocalSources = true;

  buildPhase = ''
    mkdir -p $NIX_BUILD_TOP/npm-project-root
    cd $NIX_BUILD_TOP/npm-project-root

    cp $src/package.json .
    cp $src/package-lock.json .

    export HOME=$PWD/.home
    export npm_config_cache=$PWD/.npm

    while IFS= read -r package || [ "$package" ]; do
      echo "caching $package"
      npm cache add "$package"
    done <${tarballsFile}

    npm ci
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp -r $NIX_BUILD_TOP/npm-project-root/node_modules $out/lib/

    mkdir -p $out/bin
    ln -s $out/lib/node_modules/@herb-tools/language-server/bin/herb-language-server $out/bin/herb-language-server
    ln -s $out/lib/node_modules/@herb-tools/formatter/bin/herb-format $out/bin/herb-format
    ln -s $out/lib/node_modules/@herb-tools/linter/bin/herb-lint $out/bin/herb-lint
  '';
}
