#! /usr/bin/env bash

((EUID == 0)) && sudo='' || sudo=sudo

if (($#)) && [[ $1 != '-a' ]]; then
   $sudo emerge --verbose --ask "$@"
else
   # eix-sync
   $sudo emerge --sync
   $sudo eix-update

   # -vauND
   if $sudo emerge --verbose --ask --update --newuse --deep --with-bdeps=y world
   then
      $sudo emerge --ask --depclean # (-c)
      $sudo revdep-rebuild
   fi

   if [[ $1 == '-a' ]]; then
      $sudo eclean -i distfiles
      if $sudo emaint --check world; then
         $sudo emaint --fix   world
      fi
   fi
fi
