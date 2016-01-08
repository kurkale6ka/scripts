# Colorful messages
#    supports setting the following attributes:
#                     bold (-s for strong)
#               underlined (-u)
#              fg/bg color (-f/-b)
#      no trailing newline (-n)
#      printf style format (-p)
#           set a variable (-v)
#
# Examples:
# for i in {0..255}; do cecho -p'%s%03d  ' -f"$i" color "$i"; ((i%7 == 0)) && echo; done; echo
#
# cecho -fblue -bgreen -su message
# cecho -v -sfblue:39 var val
# cecho -n -fylw:221 message # 256 colors support (ylw: is optional)
#
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

   local opt _fmt

   while getopts 'suf:b:np:v' opt
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
          n) # format already set by -p
             if [[ $_fmt ]]
             then
                _fmt="${_fmt//\\n/}"
             else
                _fmt=%s
             fi
             ;;
          p) # format already set to %s by -n
             if [[ $_fmt ]]
             then
                _fmt="${OPTARG//\\n/}"
             else
                _fmt="$OPTARG"
             fi
             ;;
          v) local _cset=1 ;;
         \?) echo "Invalid option: -$OPTARG" 1>&2
             return 1 ;;
      esac
   done

   ((error)) && return 2

   shift "$((OPTIND-1))"

   ## Output
   local _res="$(tput sgr0 || tput me)"

   if ((_cset))
   then
      if (($# == 0))
      then
         local var val
         while read -r var val
         do
            eval $var="'${_bld}${_udl}${_fg}${_bg}${val}${_res}'"
         done
      else
         eval $1="'${_bld}${_udl}${_fg}${_bg}${@:2}${_res}'"
      fi
   else
      # Without arguments, read from STDIN
      if (($# == 0))
      then
         echo -n "${_bld}${_udl}${_fg}${_bg}"
         while read -r
         do
            printf "${_fmt:-%s\n}" "$REPLY"
         done
         echo -n "$_res"
      else
         printf "${_bld}${_udl}${_fg}${_bg}${_fmt:-%s\n}${_res}" "$@"
      fi
   fi
}

# vim: fde=getline(v\:lnum)=~'^\\s*##'?'>'.(len(matchstr(getline(v\:lnum),'###*'))-1)\:'='
