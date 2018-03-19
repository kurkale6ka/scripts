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

   # XDG setup
   . "$REPOS_BASE"/zsh/.zshenv
   mkdir -p "$XDG_CONFIG_HOME"
   mkdir -p "$XDG_DATA_HOME"
   [[ ! -f $HOME/.zshenv ]] && cp "$REPOS_BASE"/zsh/.zshenv "$HOME"/.zshenv

   echo "* ${_blu}Linking dot files${_res}..."
   mklinks

   echo "* ${_blu}Creating fuzzy cd database${_res}..."
   . "$REPOS_BASE"/scripts/mkdb
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

      # zsh
      if mkdir -p {"$XDG_CONFIG_HOME","$XDG_DATA_HOME"}/zsh
      then
         ln -sf "$REPOS_BASE"/zsh/.zshenv   ~
         ln -sf "$REPOS_BASE"/zsh/autoload  "$XDG_CONFIG_HOME"/zsh
         ln -sf "$REPOS_BASE"/zsh/.zprofile "$XDG_CONFIG_HOME"/zsh
         ln -sf "$REPOS_BASE"/zsh/.zshrc    "$XDG_CONFIG_HOME"/zsh
      fi
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

      # zsh
      'rm' ~/.zshenv
      'rm' "$XDG_CONFIG_HOME"/zsh/autoload
      'rm' "$XDG_CONFIG_HOME"/zsh/.zprofile
      'rm' "$XDG_CONFIG_HOME"/zsh/.zshrc
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
}

opts[0]='Initial setup'
opts[1]='Create fuzzy cd database'
opts[2]='Make links'
opts[3]='Remove links'

select choice in "${opts[@]}"
do
   case "$choice" in
      "${opts[0]}") initial_setup;                break;;
      "${opts[1]}") . "$REPOS_BASE"/scripts/mkdb; break;;
      "${opts[2]}") mklinks;                      break;;
      "${opts[3]}") rmlinks;                      break;;
                 *) echo '*** Wrong choice ***' >&2
   esac
done

# vim: foldmethod=indent
