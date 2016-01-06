# Colorful messages
#    supports setting the following attributes:
#      fg/bg color (-f/-b)
#             bold (-s for strong)
#       underlined (-u)
#
# Examples:
# cecho -fblue -bgreen -su message
# cecho -fylw:221 message # 256 colors support (ylw: is optional)
# cecho -usfcyan << EOM
# Hello
# World
# EOM

cecho() {

   ## colors
   local color error

   _get_color() {
      case "$1" in
          black) color=0 ;;
            red) color=1 ;;
          green) color=2 ;;
         yellow) color=3 ;;
           blue) color=4 ;;
         purple) color=5 ;;
           cyan) color=6 ;;
          white) color=7 ;;
         [0-9]*) color="$1" ;;
              *) echo 'Unrecognized color' 1>&2
                 error=1
                 ;;
      esac
   }

   ## options
   OPTIND=1

   local opt
   while getopts 'usb:f:' opt
   do
      case "$opt" in
          f) _get_color "${OPTARG#*:}"
             ((error)) && return 1
             local _fg="$(tput setaf "$color" || tput AF "$color")"
             ;;
          b) _get_color "${OPTARG#*:}"
             ((error)) && return 2
             local _bg="$(tput setab "$color" || tput AB "$color")"
             ;;
          s) local _bld="$(tput bold || tput md)" ;;
          u) local _udl="$(tput smul || tput us)" ;;
         \?) echo "Invalid option: -$OPTARG" 1>&2
             return 3 ;;
      esac
   done

   shift "$((OPTIND-1))"

   ## Output
   local _res="$(tput sgr0 || tput me)"

   # Without arguments, read from STDIN
   if (($# == 0))
   then
      local messages=()
      while read -r
      do
         messages+=("$REPLY")
      done

      echo -n "${_bld}${_udl}${_fg}${_bg}"
      printf '%s\n' "${messages[@]}"
      echo -n "${_res}"
   else
      echo "${_bld}${_udl}${_fg}${_bg}${@}${_res}"
   fi
}

# vim: fde=getline(v\:lnum)=~'^\\s*##'?'>'.(len(matchstr(getline(v\:lnum),'###*'))-1)\:'='
