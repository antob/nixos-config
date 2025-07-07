{ pkgs, ... }:

pkgs.writeShellScriptBin "pinentry-tofi" ''
  set -eu

  VERSION="0.0.1"

  log_debug() {
      echo "$@" >> /dev/null #/tmp/pinentry-log.txt
  }

  assuan_send() {
      log_debug "assuan_send: $*"
      echo "$@"
  }

  split_line() {
      rmfirst=''${2:-0}
      log_debug "args: \"$1\", ''${rmfirst}"
      read -ra out_arr <<< "$1"
      log_debug "out: $(declare -p out_arr)"
      if [ "$rmfirst" -ne 1 ] ; then
          unset "out_arr[0]"
      fi
      echo "''${out_arr[@]}"
  }

  # Originally from https://github.com/sfinktah/bash/blob/master/rawurlencode.inc.sh
  # There is also more explanation and documentation there
  rawurlencode() {
      local string="''${1}"
      local strlen=''${#string}
      local encoded=""
      local pos c o

      for (( pos=0 ; pos<strlen ; pos++ )); do
          c=''${string:$pos:1}
          case "$c" in
            [-_.~a-zA-Z0-9] ) o="''${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
          esac
          encoded+="''${o}"
      done
      printf "%s" "''${encoded}"    # You can either set a return variable (FASTER)
  }

  rawurldecode() {
      # This is perhaps a risky gambit, but since all escape characters must be
      # encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
      # will decode hex for us

      printf '%b' "''${1//%/\\x}"
  }

  # Except Assuan apparently doesn't want really encoded strings, but some kind of bastard
  basturlencode () {
      echo "$1" | sed -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
  }

  tofi_cmd="${pkgs.tofi}/bin/tofi --hide-input true --require-match false"
  win_prompt="Password"
  keyinfo=""

  main () {
      local temp_str

      assuan_send "OK Please go ahead"

      while : ; do
          read -r line
          log_debug "line=$line"
          # Set options for the connection.  The syntax of such a line is
          # OPTION name [ [=] value ]
          # Leading and trailing spaces around name and value are
          # allowed but should be ignored.  For compatibility reasons, name
          # may be prefixed with two dashes.  The use of the equal sign
          # is optional but suggested if value is given.
          if [[ "$line" =~ ^OPTION ]] ; then
              # OPTION grab
              # OPTION ttyname=/dev/pts/1
              # OPTION ttytype=tmux-256color
              # OPTION lc-messages=C
              assuan_send "OK"
          elif [[ "$line" =~ ^GETINFO ]] ; then
              # https://www.gnupg.org/documentation/manuals/gnupg/Agent-GETINFO.html
              # version or pid of this script?
              # gpg-agent --version works but it must be filtered
              IFS=" " line_arr=($(split_line "$line"))
              log_debug "line_arr: ''${line_arr[*]}"
              subcommand=''${line_arr[0]}
              log_debug "subcommand=''${subcommand}"
              if [[ "$subcommand" == "version" ]] ; then
                  assuan_send "D ''${VERSION}"
              elif [[ "$subcommand" == "pid" ]] ; then
                  assuan_send "D $$"
              fi
              assuan_send "OK"
          # This command is reserved for future extensions.
          # True NOOP
          elif [[ "$line" =~ ^CANCEL ]] ; then
              assuan_send "OK"
          # This command is reserved for future extensions.  Not yet
          # specified as we don't implement it in the first phase.  See
          # Werner's mail to gpa-dev on 2001-10-25 about the rationale
          # for measurements against local attacks.
          # True NOOP
          elif [[ "$line" =~ ^AUTH ]] ; then
              assuan_send "OK"
          # And this actually is NOOP
          elif [[ "$line" =~ ^NOP ]] ; then
              assuan_send "OK"
          elif [[ "$line" =~ ^KEYINFO ]] ; then
              assuan_send "''${keyinfo}"
              assuan_send "OK"
          elif [[ "$line" =~ ^SETKEYINFO ]] ; then
              IFS=" " line_arr=($(split_line "$line"))
              log_debug "line_arr: ''${line_arr[*]}"
              if [[ "''${line_arr[0]}" =~ ^--clear ]] ; then
                  keyinfo=""
              else
                  keyinfo="''${line_arr[*]}"
              fi
              assuan_send "OK"
          elif [[ "$line" =~ ^SETOK|^SETNOTOK|^SETERROR|^SETCANCEL|^SETTIMEOUT|^SETQUALITYBAR|^SETGENPIN ]] ; then
              assuan_send "OK"
          elif [[ "$line" =~ ^CONFIRM|^MESSAGE ]] ; then
              assuan_send "OK"
          # Reset the connection but not any existing authentication.
          # The server should release all resources associated with the
          # connection.
          elif [[ "$line" =~ ^RESET ]] ; then
              assuan_send "OK"
          elif [[ "$line" =~ ^SETDESC ]] ; then
              #SETDESC Please enter the passphrase for the ssh key%0A  ke:yf:in:ge:rp:ri:nt
              assuan_send "OK"
          elif [[ "$line" =~ ^SETPROMPT ]] ; then
              #SETPROMPT Passphrase:
              IFS=" " line_arr=($(split_line "$line"))
              log_debug "line_arr: ''${line_arr[*]}"
              win_prompt="''${line_arr[0]}"
              assuan_send "OK"
          elif [[ "$line" =~ ^SETTITLE ]] ; then
              assuan_send "OK"
          elif [[ "$line" =~ ^GETPIN ]] ; then
              passw=None
              tofi_cmd+=" --prompt-text '$win_prompt' < /dev/null"
              log_debug "''${tofi_cmd}"
              passw="$(eval "''${tofi_cmd}")"
              passw_err=$?
              if [[ ''${passw_err} -ne 0 ]] ; then
                  # assuan_send "ERR 83886179 Operation cancelled <rofi>"
                  log_debug "rofi failed to run: ''${passw} / ''${passw_err}"
                  exit $passw_err
              else
                  if [[ -n ''${passw} ]] ; then
                      assuan_send "D ''${passw}"
                  fi
              fi
              assuan_send "OK"
          # Close the connection.  The server will respond with OK.
          elif [[ ''${line} =~ ^BYE ]] ; then
              exit 0
          else
              assuan_send "BYE"
              exit 1
          fi
      done
  }

  if [ "$0" = "$BASH_SOURCE" ]; then
      if [ "$XDG_SESSION_TYPE" != "tty" ] ; then
          main
      else
          exec pinentry-tty "$@"
      fi
  fi
''
