#! /usr/bin/env bash

mkdir -p ~/.adom.data/savedg/backup

# on start: restore from your personal backup
rsync -ai ~/.adom.data/savedg/backup/ ~/.adom.data/savedg

if [[ $(uname) == Darwin ]]
then
   open "$(mdfind ADOM.app)"
else
   adom
fi

_red="$(tput setaf 1 || tput AF 1)"
_res="$(tput sgr0 || tput me)"

printf "${_red}Before finishing, don't forget to update your own backup${_res}:\n"
echo "rsync -ai -f'- backup/' ~/.adom.data/savedg/ ~/.adom.data/savedg/backup"
