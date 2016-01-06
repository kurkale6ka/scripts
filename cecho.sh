# Colorful messages
#    supports setting the following attributes:
#      fg/bg color (-f/-b)
#             bold (-s for strong)
#       underlined (-u)
# examples:
#    cecho -fblue -bgreen -su message
#    cecho -fylw:221 message # 256 colors support (ylw: is optional)
cecho() {

   local _bld="$(tput bold || tput md)"
   local _udl="$(tput smul || tput us)"
   local _res="$(tput sgr0 || tput me)"

   OPTIND=1

   local opt
   while getopts ':f:b:su' opt
   do
      case "$opt" in
          f) local _fg="$OPTARG" ;;
          b) local _bg="$OPTARG" ;;
          s) local _b=1 ;;
          u) local _u=1 ;;
         \?) echo "Invalid option: -$OPTARG" 1>&2
             return 1 ;;
      esac
   done

   shift "$((OPTIND-1))"

   local color

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
                 return 2
                 ;;
      esac
   }

   local fg bg

   if [[ $_fg ]]
   then
      _get_color "${_fg#*:}"
      fg="$(tput setaf "$color" || tput AF "$color")"
   fi

   if [[ $_bg ]]
   then
      _get_color "${_bg#*:}"
      bg="$(tput setab "$color" || tput AB "$color")"
   fi

   # If no arguments are given, read from STDIN
   if (($# == 0))
   then
      local messages=()
      while read -r
      do
         messages+=("$REPLY")
      done
   fi

   [[ $_b ]] && echo -n "$_bld"
   [[ $_u ]] && echo -n "$_udl"

   if (($# != 0))
   then
      echo "${fg}${bg}${@}${_res}"
   else
      echo -n "${fg}${bg}"
      printf '%s\n' "${messages[@]}"
      echo -n "${_res}"
   fi
}
