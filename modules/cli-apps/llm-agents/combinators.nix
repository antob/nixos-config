{ lib }:
combinators:
with combinators;
let
  resolveGitRoot = include-once "_resolve-git-root" (add-runtime ''
    function _resolveGitRoot {
      GIT_ROOT=""
      local _GITDIR
      if [ -f "$PWD/.git" ]; then
        _GITDIR="$(grep -m1 '^gitdir:' "$PWD/.git" | sed 's/^gitdir: *//')"
        case "$_GITDIR" in
          /*) ;;
          *) _GITDIR="$PWD/$_GITDIR" ;;
        esac
        _GITDIR="$(realpath "$_GITDIR")"
        case "$_GITDIR" in
          */worktrees/*)
            _GITDIR="''${_GITDIR%/worktrees/*}"
            ;;
        esac
        GIT_ROOT="''${_GITDIR%/.git}"
      elif [ -d "$PWD/.git" ]; then
        GIT_ROOT="$PWD"
      fi
    }
  '');
in
{
  mount-git-root = include-once "mount-git-root" (compose [
    resolveGitRoot
    (add-runtime ''
      _resolveGitRoot
      if [ -n "''${GIT_ROOT:-}" ] && [ -f "$PWD/.git" ]; then
        RUNTIME_ARGS+=(--bind "$GIT_ROOT/.git" "$GIT_ROOT/.git")
      fi
    '')
  ]);

  try-readonly-path-from-git-root =
    path:
    compose [
      resolveGitRoot
      (add-runtime ''
        _resolveGitRoot
        if [ -n "''${GIT_ROOT:-}" ]; then
          _jail_path=${lib.escapeShellArg path}
          RUNTIME_ARGS+=(--ro-bind-try "$GIT_ROOT/$_jail_path" "$GIT_ROOT/$_jail_path")
        fi
      '')
    ];

  try-readwrite-path-from-git-root =
    path:
    compose [
      resolveGitRoot
      (add-runtime ''
        _resolveGitRoot
        if [ -n "''${GIT_ROOT:-}" ]; then
          _jail_path=${lib.escapeShellArg path}
          RUNTIME_ARGS+=(--bind-try "$GIT_ROOT/$_jail_path" "$GIT_ROOT/$_jail_path")
        fi
      '')
    ];
}
