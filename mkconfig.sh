#! /usr/bin/env bash

# run this script with:
# ---------------------
# bash <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.sh)
#
# This script is meant for remote systems only, where the default shell is bash

_red="$(tput setaf 1 || tput AF 1)"
_res="$(tput sgr0 || tput me)"

if [[ -z $REPOS_BASE ]]
then
   REPOS_BASE=~/github
fi

initial_setup() {
   mkdir -p "$REPOS_BASE"

   # XDG setup
   . "$REPOS_BASE"/zsh/.zshenv

   mkdir -p "$XDG_CONFIG_HOME"
   mkdir -p "$XDG_DATA_HOME"

   if [[ ! -f $HOME/.zshenv ]]
   then
      cp "$REPOS_BASE"/zsh/.zshenv "$HOME"/.zshenv
   fi

   echo '* Linking dot files'
   links add

   echo '* Creating fuzzy cd database'
   . "$REPOS_BASE"/scripts/mkdb
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

   # ~/bin
   if [[ $1 == add ]]
   then
      mkdir -p ~/bin
      ln -sf "$REPOS_BASE"/scripts/mkconfig.sh ~/bin/mkconfig
   else
      'rm' ~/bin/mkconfig
   fi

   # misc configs
   for config in .gitignore .irbrc .pyrc .Xresources
   do
      if [[ $1 == add ]]
      then
         ln -sf "$REPOS_BASE"/config/dotfiles/"$config" ~
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
   exit
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
         print -P "Error: unknown option %F{red}$1%f" >&2
         exit 1
         ;;
      *)
         break
         ;;
   esac
done

if (($#))
then
   echo 'Non-option arguments not allowed.' >&2
   _help 1
   exit 1
fi

# Initial setup
if [[ ${switches[*]} == *i* ]]
then
   initial_setup
   exit
fi

# Create fuzzy cd database
if [[ ${switches[*]} == *c* ]]
then
   . "$REPOS_BASE"/scripts/mkdb
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
