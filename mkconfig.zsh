#! /usr/bin/env zsh

# run this script with:
# ------------
# zsh <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig)
#
# vim-plug (after cloning):
# -------------------------
# curl -fLo $REPOS_BASE/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# PluginInstall

if [[ -z $REPOS_BASE ]]
then
   print -P '%F{red}REPOS_BASE empty%f'
   read 'REPLY?defaulting to ~/github (change value or enter to accept): '
   REPOS_BASE=${REPLY:-~/github}
   echo
fi

setopt extended_glob

# Don't update my cd bookmarks for automated cds
chpwd_functions=()

initial_setup() {
   mkdir -p $REPOS_BASE
   if cd $REPOS_BASE
   then
      print -P "* %F{45}Cloning repositories in %F{blue}${REPOS_BASE/$HOME/~}%f..."
      [[ ! -d zsh     ]] && git clone git@github.com:kurkale6ka/zsh.git
      [[ ! -d bash    ]] && git clone git@github.com:kurkale6ka/bash.git
      [[ ! -d help    ]] && git clone git@github.com:kurkale6ka/help.git
      [[ ! -d config  ]] && git clone git@github.com:kurkale6ka/config.git
      [[ ! -d scripts ]] && git clone git@github.com:kurkale6ka/scripts.git
      [[ ! -d vim     ]] && git clone git@github.com:kurkale6ka/vim.git
      echo
   fi

   if ssh-add -l 1>/dev/null 2>&1
   then
      print -P '* %F{45}Configuring git%f...'
      . $REPOS_BASE/config/git.bash
   else
      print -P '%F{red}Please upload your key to GitHub%f: ssh-keygen -b4096 -trsa' 1>&2
      return 1
   fi

   if [[ $(uname) == Darwin ]]
   then
      if (( $+commands[brew] ))
      then
         print -P "* %F{45}Installing Homebrew formulae%f..."
         brew install zsh
         brew install coreutils
         brew install ed --with-default-names
         brew install findutils --with-default-names
         brew install ag
         brew install colordiff
         brew install ctags
         brew install dos2unix
         brew install gcal
         brew install tree
         brew install mariadb
         brew install gawk
         brew install gnu-sed --with-default-names
         brew install gnu-tar --with-default-names
         brew install grep --with-default-names
         brew install tmux
         brew install weechat --with-aspell --with-python --with-perl --with-ruby
         brew install wgetpaste
         brew install iproute2mac
         brew install nmap
         brew install tcpdump
         brew install telnet
         brew install moreutils --without-parallel
         brew install parallel --force
         brew install shellcheck
         brew install vim --with-override-system-vi
         brew tap neovim/neovim
         brew install --HEAD neovim
         echo
      else
         print -P '%F{red}Please install Homebrew%f' 1>&2
         return 2
      fi
      # Fix Homebrew PATHs
      path=("$(brew --prefix coreutils)"/libexec/gnubin $path)
      typeset -Ug path
   else
      # TODO
      # pacman -S ...
   fi

   # XDG setup
   . $REPOS_BASE/zsh/.zshenv
   [[ ! -f $HOME/.zshenv ]] && cp $REPOS_BASE/zsh/.zshenv $HOME/.zshenv

   print -P '* %F{45}Linking dot files%f...'
   mklinks

   print -P '* %F{45}Generating tags%f...'
   mktags

   print -P '* %F{45}Creating fuzzy cd database%f...'
   . $REPOS_BASE/scripts/mkdb
}

updaterepos() {
   for repo in $REPOS_BASE/*(/)
   do
      if cd $repo
      then
         git fetch -q
         if [[ $(git symbolic-ref --short HEAD) == master ]] && git status -sb | grep -q behind
         then
            print -nP "%F{45}${repo:t}%f: "
            git pull
         fi
      fi
   done
}

mktags() {
   if [[ -z $XDG_CONFIG_HOME ]]
   then
      print -P 'mktags (zsh): %F{red}XDG setup needed%f' 1>&2
      return 3
   fi

   # Cheat by treating zsh files as sh
   # note: $REPOS_BASE/zsh/autoload can't be added since the function names are 'missing'
   if cd $REPOS_BASE
   then
      ctags -R                                   \
         --langmap=vim:+.vimrc,sh:+.after        \
         --exclude='*~ '                         \
         --exclude='.*~'                         \
         --exclude=plugged                       \
         --exclude=colors                        \
         --exclude=keymap                        \
         --exclude=plug.vim                      \
         $XDG_CONFIG_HOME/zsh                    \
         $REPOS_BASE/scripts                     \
         $REPOS_BASE/vim                         \
         $REPOS_BASE/vim/plugged/vsearch         \
         $REPOS_BASE/vim/plugged/vim-blockinsert \
         $REPOS_BASE/vim/plugged/vim-chess       \
         $REPOS_BASE/vim/plugged/vim-desertEX    \
         $REPOS_BASE/vim/plugged/vim-pairs       \
         $REPOS_BASE/vim/plugged/vim-swap
   fi
}

bash=(.bash_{profile,logout} .bashrc)
configs=(.gitignore .irbrc .pyrc .Xresources)
exes=(colors_term.bash colors_tmux.bash mkconfig)

mklinks() {
   # Vim
   ln -sfT $REPOS_BASE/vim ~/.vim
   ln -sf  $REPOS_BASE/vim/.{,g}vimrc ~

   if [[ -n $XDG_CONFIG_HOME ]]
   then
      # nvim
      ln -sfT $REPOS_BASE/vim $XDG_CONFIG_HOME/nvim

      # zsh
      if mkdir -p {$XDG_CONFIG_HOME,$XDG_DATA_HOME}/zsh
      then
         ln -sf $REPOS_BASE/zsh/.zshenv   ~
         ln -sf $REPOS_BASE/zsh/autoload  $XDG_CONFIG_HOME/zsh
         ln -sf $REPOS_BASE/zsh/.zprofile $XDG_CONFIG_HOME/zsh
         ln -sf $REPOS_BASE/zsh/.zshrc    $XDG_CONFIG_HOME/zsh
      fi

      # ranger
      if mkdir -p $XDG_CONFIG_HOME/ranger
      then
         ln -sf $REPOS_BASE/config/ranger/rc.conf $XDG_CONFIG_HOME/ranger
      fi
   else
      print -P 'mklinks (nvim, zsh, ranger): %F{red}XDG setup needed%f' 1>&2
   fi

   # Bash
   for c in $bash; ln -sf $REPOS_BASE/bash/$c ~

   # Misc configs
   ln -sf $REPOS_BASE/config/ctags/.ctags ~
   ln -sf $REPOS_BASE/config/tmux/.tmux.conf ~

   for c in $configs; ln -sf $REPOS_BASE/config/dotfiles/$c ~
   ln -sf ~/.gitignore ~/.agignore

   # ~/bin
   if mkdir -p ~/bin
   then
      for c in $exes; ln -sf $REPOS_BASE/scripts/$c ~/bin

      ln -sf $REPOS_BASE/vim/extra/vc ~/bin
      ln -sf $REPOS_BASE/config/tmux/lay ~/bin
   fi
}

rmlinks() {
   # Vim
   'rm' ~/.vim
   'rm' ~/.{,g}vimrc

   if [[ -n $XDG_CONFIG_HOME ]]
   then
      # nvim
      'rm' $XDG_CONFIG_HOME/nvim

      # zsh
      'rm' ~/.zshenv
      'rm' $XDG_CONFIG_HOME/zsh/autoload
      'rm' $XDG_CONFIG_HOME/zsh/.zprofile
      'rm' $XDG_CONFIG_HOME/zsh/.zshrc

      # ranger
      'rm' $XDG_CONFIG_HOME/ranger/rc.conf
   fi

   # Bash
   for c in $bash; 'rm' ~/$c

   # Misc configs
   'rm' ~/{.ctags,.tmux.conf}
   for c in $configs; 'rm' ~/$c
   'rm' ~/.agignore

   # ~/bin
   for c in $exes; 'rm' ~/bin/$c
   'rm' ~/bin/vc
   'rm' ~/bin/lay
}

opts[1]='Update repositories'
opts[2]='Initial setup'
opts[3]='Generate tags'
opts[4]='Create fuzzy cd database'
opts[5]='Make links'
opts[6]='Remove links'

select choice in $opts
do
   case $choice in
      (${opts[1]}) updaterepos;                break;;
      (${opts[2]}) initial_setup;              break;;
      (${opts[3]}) mktags;                     break;;
      (${opts[4]}) . $REPOS_BASE/scripts/mkdb; break;;
      (${opts[5]}) mklinks;                    break;;
      (${opts[6]}) rmlinks;                    break;;
               (*) echo '*** Wrong choice ***' >&2
   esac
done

# vim: foldmethod=indent
