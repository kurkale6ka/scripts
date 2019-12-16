#! /usr/bin/env bash

# run this script with:
# ---------------------
# bash <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.sh)
#
# This script is meant for remote systems only, where the default shell is bash

# Usage: mkconfig -iclL
#
# -i: Initial setup
# -c: Create fuzzy cd database
# -l: Make links
# -L: Remove links

_red="$(tput setaf 1 || tput AF 1)"
_res="$(tput sgr0 || tput me)"

if [[ -z $REPOS_BASE ]]
then
   export REPOS_BASE=~/github
fi

initial_setup() {
   mkdir -p "$REPOS_BASE"

   # XDG setup
   . "$REPOS_BASE"/zsh/.zshenv

   mkdir -p "$XDG_CONFIG_HOME"
   mkdir -p "$XDG_DATA_HOME"

   echo '* Linking dot files'
   links add

   echo '* Creating fuzzy cd database'
   . "$REPOS_BASE"/scripts/db-create
}

links() {
   # vim
   if [[ $1 == add ]]
   then
      ln -sfT "$REPOS_BASE"/vim        ~/.vim
      ln -sf  "$REPOS_BASE"/vim/.vimrc ~
   else
      'rm' ~/.vim
      'rm' ~/.vimrc
   fi

   local config

   # bash
   for config in .bash_profile .bashrc .bash_logout
   do
      if [[ $1 == add ]]
      then
         ln -sf "$REPOS_BASE"/bash/"$config" ~
      else
         'rm' ~/"$config"
      fi
   done
}

# if no arguments, initial setup
if (($# == 0))
then
   echo 'Initial setup...'
   initial_setup
   exec bash
fi

_help() {
local info
read -r -d $'\0' info << 'HELP'
Usage: mkconfig -iclL

-i: Initial setup
-c: Create fuzzy cd database
-l: Make links
-L: Remove links
HELP
if (($1 == 0))
then echo "$info"
else echo "$info" >&2
fi
}

switches=()

# Command line options
while :
do
   case "$1" in
      -h|--help)
         _help 0
         exit
         ;;
      -i|--ini)
         switches+=(i)
         shift
         ;;
      -c|--gen-c-db)
         switches+=(c)
         shift
         ;;
      -l|--links)
         if [[ ${switches[*]} != *L* ]]
         then
            switches+=(l)
         fi
         shift
         ;;
      -L|--del-links)
         if [[ ${switches[*]} != *l* ]]
         then
            switches+=(L)
         fi
         shift
         ;;
      -?*)
         echo "Error: unknown option ${_red}$1${_res}" >&2
         exit 1
         ;;
      *)
         break
         ;;
   esac
done

if (($#))
then
   echo "${_red}Non-option arguments not allowed${_res}" >&2
   _help 1
   exit 1
fi

# Initial setup
if [[ ${switches[*]} == *i* ]]
then
   initial_setup
   exec bash
fi

# Create fuzzy cd database
if [[ ${switches[*]} == *c* ]]
then
   . "$REPOS_BASE"/scripts/db-create
fi

# Make/remove links
if [[ ${switches[*]} == *l* ]]
then
   links add
elif [[ ${switches[*]} == *L* ]]
then
   links del
fi

# vim: foldmethod=indent
