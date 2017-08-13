#! /usr/bin/env bash

# Usage: adom.sh [-s|-r]

mkdir -p ~/.adom.data/savedg/backup

adom_start() {
   if [[ $(uname) == Darwin ]]
   then
      open "$(mdfind ADOM.app)"
   else
      adom-noteye || adom
   fi
}

OPTIND=1

while getopts ':sr' opt
do
   case "$opt" in
       # update/create a personal backup
       s) rsync -ai -f'- backup/' ~/.adom.data/savedg/ ~/.adom.data/savedg/backup
          exit
          ;;
       # restore from your personal backup
       r) rsync -ai ~/.adom.data/savedg/backup/ ~/.adom.data/savedg
          adom_start
          exit
          ;;
      \?) echo "Invalid option: -$OPTARG" 1>&2; exit 1
          ;;
   esac
done

shift "$((OPTIND-1))"

adom_start
