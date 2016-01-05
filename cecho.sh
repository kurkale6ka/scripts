# Colorful messages
#    * supports setting the following attributes:
#      fg/bg color, bold (strong) and underlined
#    * 256 colors support
# examples:
#    cecho -fblue -bgreen -su 'message'
#    cecho -f221 'message'
cecho() {

   local _bld="$(tput bold || tput md)"
   local _udl="$(tput smul || tput us)"
   local _res="$(tput sgr0 || tput me)"

   OPTIND=1

   # f - foreground
   # b - background
   # s - strong
   # u - underlined
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

   shift $((OPTIND-1))

   local fg
   local bg

   # 0 - Black    4 - Blue
   # 1 - Red      5 - Purple
   # 2 - Green    6 - Cyan
   # 3 - Yellow   7 - White
   if [[ $_fg ]]
   then
      # setaf -> foreground
      # setab -> background
      case "$_fg" in
                                    black) fg="$(tput setaf 0      || tput AF 0)"      ;;
                                      red) fg="$(tput setaf 1      || tput AF 1)"      ;;
                                    green) fg="$(tput setaf 2      || tput AF 2)"      ;;
                                   yellow) fg="$(tput setaf 3      || tput AF 3)"      ;;
                                     blue) fg="$(tput setaf 4      || tput AF 4)"      ;;
                                   purple) fg="$(tput setaf 5      || tput AF 5)"      ;;
                                     cyan) fg="$(tput setaf 6      || tput AF 6)"      ;;
                                    white) fg="$(tput setaf 7      || tput AF 7)"      ;;
         [0-9]|[0-9][0-9]|[0-9][0-9][0-9]) fg="$(tput setaf "$_fg" || tput AF "$_fg")" ;;
                                        *) echo 'Unrecognized fg color' 1>&2 ;;
      esac
   fi

   if [[ $_bg ]]
   then
      case "$_bg" in
                                    black) bg="$(tput setab 0      || tput AB 0)"      ;;
                                      red) bg="$(tput setab 1      || tput AB 1)"      ;;
                                    green) bg="$(tput setab 2      || tput AB 2)"      ;;
                                   yellow) bg="$(tput setab 3      || tput AB 3)"      ;;
                                     blue) bg="$(tput setab 4      || tput AB 4)"      ;;
                                   purple) bg="$(tput setab 5      || tput AB 5)"      ;;
                                     cyan) bg="$(tput setab 6      || tput AB 6)"      ;;
                                    white) bg="$(tput setab 7      || tput AB 7)"      ;;
         [0-9]|[0-9][0-9]|[0-9][0-9][0-9]) bg="$(tput setab "$_bg" || tput AB "$_bg")" ;;
                                        *) echo 'Unrecognized bg color' 1>&2 ;;
      esac
   fi

   [[ $_b ]] && echo -n "$_bld"
   [[ $_u ]] && echo -n "$_udl"

   echo "${fg}${bg}${@}${_res}"
}
