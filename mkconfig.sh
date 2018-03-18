#! /usr/bin/env bash

# run this script with:
# ---------------------
# bash <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.sh)
#
# vim-plug (after cloning):
# -------------------------
# curl -fLo "$REPOS_BASE"/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# PluginInstall

_red="$(tput setaf 1 || tput AF 1)"
_blue="$(tput setaf 4 || tput AF 4)"
_blu="$(tput setaf 45 || tput AF 45)"
_res="$(tput sgr0 || tput me)"

if [[ -z $REPOS_BASE ]]
then
   echo "${_red}REPOS_BASE empty${_res}"
   read -p 'defaulting to ~/github (change value or enter to accept): '
   REPOS_BASE=${REPLY:-~/github}
   echo
fi

initial_setup() {
   mkdir -p "$REPOS_BASE"

   if command -v git >/dev/null 2>&1
   then
      if cd "$REPOS_BASE"
      then
         echo "* ${_blu}Cloning repositories in ${_blue}${REPOS_BASE/$HOME/~}${_res}..."

         [[ ! -d zsh     ]] && git clone git@github.com:kurkale6ka/zsh.git
         [[ ! -d bash    ]] && git clone git@github.com:kurkale6ka/bash.git
         [[ ! -d help    ]] && git clone git@github.com:kurkale6ka/help.git
         [[ ! -d config  ]] && git clone git@github.com:kurkale6ka/config.git
         [[ ! -d scripts ]] && git clone git@github.com:kurkale6ka/scripts.git
         [[ ! -d vim     ]] && git clone git@github.com:kurkale6ka/vim.git

         echo

         if [[ -d config ]]
         then
            if ssh-add -l 1>/dev/null 2>&1
            then
               echo "* ${_blu}Configuring git${_res}..."
               . "$REPOS_BASE"/config/git.bash
            else
               echo "${_red}Please upload your key to GitHub${_res}: ssh-keygen -b4096 -trsa" 1>&2
               return 1
            fi
         fi
      fi
   elif [[ ! -d $REPOS_BASE/bash ]]
   then
      echo "${_red}git isn't installed. please upload manually your config files!${_res}" 1>&2
      return 2
   fi

   # XDG setup
   [[ -z $XDG_CONFIG_HOME ]] && export XDG_CONFIG_HOME=~/.config
   [[ -z   $XDG_DATA_HOME ]] && export   XDG_DATA_HOME=~/.local/share

   echo "* ${_blu}Linking dot files${_res}..."
   mklinks

   echo "* ${_blu}Creating fuzzy cd database${_res}..."
   . "$REPOS_BASE"/scripts/mkdb
}

updaterepos() {
   for repo in "$REPOS_BASE"/*
   do
      if [[ -d $repo ]] && cd "$repo"
      then
         git fetch -q
         if [[ $(git symbolic-ref --short HEAD) == master ]] && git status -sb | grep -q behind
         then
            echo -n "${_blu}${repo:t}${_res}: "
            git pull
         fi
      fi
   done
}

bash=(.bash_{profile,logout} .bashrc)
configs=(.gitignore .irbrc .pyrc .Xresources)
exes=(mkconfig)

mklinks() {
   # Vim
   ln -sfT "$REPOS_BASE"/vim ~/.vim
   ln -sf  "$REPOS_BASE"/vim/.vimrc ~

   if [[ -n $XDG_CONFIG_HOME ]]
   then
      # nvim
      ln -sfT "$REPOS_BASE"/vim "$XDG_CONFIG_HOME"/nvim
   else
      echo "mklinks: ${_red}XDG setup needed${_res}" 1>&2
   fi

   # Bash
   for c in "${bash[@]}"
   do
      ln -sf "$REPOS_BASE"/bash/"$c" ~
   done

   # Misc configs
   ln -sf "$REPOS_BASE"/config/tmux/.tmux.conf ~

   for c in "${configs[@]}"
   do
      ln -sf "$REPOS_BASE"/config/dotfiles/"$c" ~
   done

   ln -sf ~/.gitignore ~/.agignore

   # ~/bin
   if mkdir -p ~/bin
   then
      for c in "${exes[@]}"
      do
         ln -sf "$REPOS_BASE"/scripts/"$c" ~/bin
      done

      ln -sf "$REPOS_BASE"/vim/extra/vc ~/bin
      ln -sf "$REPOS_BASE"/config/tmux/lay ~/bin
   fi
}

rmlinks() {
   # Vim
   'rm' ~/.vim
   'rm' ~/.vimrc

   if [[ -n $XDG_CONFIG_HOME ]]
   then
      # nvim
      'rm' "$XDG_CONFIG_HOME"/nvim
   fi

   # Bash
   for c in "${bash[@]}"
   do
      'rm' ~/"$c"
   done

   # Misc configs
   'rm' ~/.tmux.conf

   for c in "${configs[@]}"
   do
      'rm' ~/"$c"
   done

   'rm' ~/.agignore

   # ~/bin
   for c in "${exes[@]}"
   do
      'rm' ~/bin/"$c"
   done

   'rm' ~/bin/vc
   'rm' ~/bin/lay
}

opts[0]='Update repositories'
opts[1]='Initial setup'
opts[2]='Create fuzzy cd database'
opts[3]='Make links'
opts[4]='Remove links'

select choice in "${opts[@]}"
do
   case "$choice" in
      "${opts[0]}") updaterepos;                  break;;
      "${opts[1]}") initial_setup;                break;;
      "${opts[2]}") . "$REPOS_BASE"/scripts/mkdb; break;;
      "${opts[3]}") mklinks;                      break;;
      "${opts[4]}") rmlinks;                      break;;
                 *) echo '*** Wrong choice ***' >&2
   esac
done

# vim: foldmethod=indent
