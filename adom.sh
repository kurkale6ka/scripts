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

cat << 'SAVE'
When finished, don't forget to update your own backup, with:
rsync -ai -f'- backup/' ~/.adom.data/savedg/ ~/.adom.data/savedg/backup
SAVE
