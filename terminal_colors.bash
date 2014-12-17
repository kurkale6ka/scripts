#! /usr/bin/env bash

# For information:
#
#        Bold=$(tput bold)
#   Underline=$(tput smul)
#       Reset=$(tput sgr0)
#       Black=$(tput setaf 0)
#     BlackBG=$(tput setab 0)
#    DarkGrey=$(printf %s "$Bold"; tput setaf 0)
#   LightGrey=$(tput setaf 7)
# LightGreyBG=$(tput setab 7)
#       White=$(printf %s "$Bold"; tput setaf 7)
#         Red=$(tput setaf 1)
#       RedBG=$(tput setab 1)
#    LightRed=$(printf %s "$Bold"; tput setaf 1)
#       Green=$(tput setaf 2)
#     GreenBG=$(tput setab 2)
#  LightGreen=$(printf %s "$Bold"; tput setaf 2)
#       Brown=$(tput setaf 3)
#     BrownBG=$(tput setab 3)
#      Yellow=$(printf %s "$Bold"; tput setaf 3)
#        Blue=$(tput setaf 4)
#      BlueBG=$(tput setab 4)
#   LightBlue=$(printf %s "$Bold"; tput setaf 4)
#      Purple=$(tput setaf 5)
#    PurpleBG=$(tput setab 5)
#        Pink=$(printf %s "$Bold"; tput setaf 5)
#        Cyan=$(tput setaf 6)
#      CyanBG=$(tput setab 6)
#   LightCyan=$(printf %s "$Bold"; tput setaf 6)

b="$(tput bold)"
u="$(tput smul)" # underline
r="$(tput sgr0)" # reset

if [[ $1 == -* ]]
then
cat << 'HELP'
Usage: colors RC RC ... RC (row column)
       colors 21 35 64

Rows:    fg (eg: tput setaf 3)
Columns: bg (eg: tput setab 7), dash (-) means default bg

Ex:
1- 1- 1- 1- | 10 10 10 10 | ... | 16 16 16 16 | 17 17 17 17
2- 2- 2- 2- | 20 20 20 20 | ... | 26 26 26 26 | 27 27 27 27
                                   \   \
                                    \   *-- 6th col (cyan bg)
            .                        *- 2nd row (green fg)
            .
4- 4- 4- 4- | 40 40 40 40 | ... | 46 46 46 46 | 47 47 47 47
 \  \  \  \
  \  \  \  *---- Bold underlined
   \  \  *--- Bold
    \  *-- Normal underlined
     *- Normal
HELP
exit 0
fi

# fg
for ((i = 0; i < 8; i++))
do
   fg="$(tput setaf "$i")"
   echo -n "$fg$i- $u$i-$r $fg$b$i- $u$i-$r "

   # bg
   for ((j = 0; j < 8; j++))
   do
      bg="$(tput setab "$j")"
      echo -n "$fg$bg$i$j $u$i$j$r$fg$bg$b $i$j $u$i$j$r$bg $r"
   done
   echo
done

echo
set -- "${1:-0-}" "${2:-35}" "${@:3}"

# lc - line, column
for lc in "$@"
do
   fg="$(tput setaf "${lc%?}")"
   if [[ $lc != *- ]]
   then
      bg="$(tput setab "${lc#?}")"
   else
      unset bg
   fi
   echo "$lc: $fg${bg}Lorem ipsum dolor ${u}sit amet, consectetur$r$fg$bg$b"\
        "adipisicing elit, ${u}sed do eiusmod!$r"
done
