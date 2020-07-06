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

export REPOS_BASE=~/github

_red="$(tput setaf 1 || tput AF 1)"
_res="$(tput sgr0 || tput me)"

if [[ ! -d $REPOS_BASE ]]
then
   echo "Missing ${_red}$REPOS_BASE${_res} directory. Quiting!" 1>&2
   exit 1
fi

# XDG setup
export XDG_CONFIG_HOME=~/.config
export   XDG_DATA_HOME=~/.local/share

initial_setup() {
   mkdir -p "$REPOS_BASE"
   mkdir -p {"$XDG_CONFIG_HOME","$XDG_DATA_HOME"}/zsh

   echo '* Linking dot files'
   links add

   echo '* Creating fuzzy cd database'
   bash "$REPOS_BASE"/scripts/db-create
}

links() {
   if [[ $1 == add ]]
   then
      # vim
      ln -srfT "$REPOS_BASE"/vim        ~/.vim
      ln -srf  "$REPOS_BASE"/vim/.vimrc ~
      # bash
      ln -srf "$REPOS_BASE"/bash/.bash_profile ~
      ln -srf "$REPOS_BASE"/bash/.bashrc       ~
      ln -srf "$REPOS_BASE"/bash/.bash_logout  ~
      # zsh
      ln -srf "$REPOS_BASE"/zsh/.zshenv   ~
      ln -sf  "$REPOS_BASE"/zsh/.zprofile "$XDG_CONFIG_HOME"/zsh
      ln -sf  "$REPOS_BASE"/zsh/.zshrc    "$XDG_CONFIG_HOME"/zsh
      ln -sf  "$REPOS_BASE"/zsh/autoload  "$XDG_CONFIG_HOME"/zsh
   else
      rm ~/.vim
      rm ~/.vimrc
      rm ~/.bash_profile
      rm ~/.bashrc
      rm ~/.bash_logout
      rm ~/.zshenv
      rm "$XDG_CONFIG_HOME"/zsh/.zprofile
      rm "$XDG_CONFIG_HOME"/zsh/.zshrc
      rm "$XDG_CONFIG_HOME"/zsh/autoload
   fi
}

# if no arguments, initial setup
if (($# == 0))
then
   echo 'Initial setup...'
   initial_setup
   if [[ $SHELL == *bash ]]
   then
      exec bash
   elif [[ $SHELL == *zsh ]]
   then
      exec zsh
   fi
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
   bash "$REPOS_BASE"/scripts/db-create
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
