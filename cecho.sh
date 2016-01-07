# Colorful messages
#    supports setting the following attributes:
#                     bold (-s for strong)
#               underlined (-u)
#              fg/bg color (-f/-b)
#      no trailing newline (-n)
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

   local opt _opt

   while getopts 'suf:b:n' opt
   do
      case "$opt" in
          s) local _bld="$(tput bold || tput md)" ;;
          u) local _udl="$(tput smul || tput us)" ;;
          f) _get_color "${OPTARG#*:}"
             local _fg="$(tput setaf "$color" || tput AF "$color")"
             ;;
          b) _get_color "${OPTARG#*:}"
             local _bg="$(tput setab "$color" || tput AB "$color")"
             ;;
          n) _opt=-n ;;
         \?) echo "Invalid option: -$OPTARG" 1>&2
             return 1 ;;
      esac
   done

   ((error)) && return 2

   shift "$((OPTIND-1))"

   ## Output
   local _res="$(tput sgr0 || tput me)"

   # Without arguments, read from STDIN
   if (($# == 0))
   then
      echo -n "${_bld}${_udl}${_fg}${_bg}"
      while read -r
      do
         echo "$REPLY"
      done
      echo -n "${_res}"
   else
      echo $_opt "${_bld}${_udl}${_fg}${_bg}${@}${_res}"
   fi
}

# vim: fde=getline(v\:lnum)=~'^\\s*##'?'>'.(len(matchstr(getline(v\:lnum),'###*'))-1)\:'='
