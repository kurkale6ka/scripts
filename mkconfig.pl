#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use File::Path 'make_path';
use File::Basename 'basename';
use Term::ANSIColor qw/color :constants/;

my $BLUE = color('ansi69');

sub links ($)
{
   my $action = shift;

   unless ($ENV{XDG_CONFIG_HOME})
   {
      warn RED.'XDG setup needed'.RESET, "\n";
      return;
   }

   make_path "$ENV{XDG_CONFIG_HOME}/zsh", "$ENV{HOME}/bin";

   # ln -sfT ~/repos/vim ~/.config/nvim
   my @symlinks = (
      # vim
      [qw( sfT  vim         ~/.config/nvim )],
      [qw( srfT vim         ~/.vim         )],
      [qw( srf  vim/.vimrc  ~              )],
      [qw( srf  vim/.gvimrc ~              )],
      # zsh
      [qw( srf zsh/.zshenv   ~             )],
      [qw( sf  zsh/.zprofile ~/.config/zsh )],
      [qw( sf  zsh/.zshrc    ~/.config/zsh )],
      [qw( sf  zsh/autoload  ~/.config/zsh )],
      # bash
      [qw( srf bash/.bash_profile ~ )],
      [qw( srf bash/.bashrc       ~ )],
      [qw( srf bash/.bash_logout  ~ )],
      # scripts
      [qw( sf scripts/mkconfig.pl      ~/bin/mkconfig )],
      [qw( sf scripts/pics.pl          ~/bin/pics     )],
      [qw( sf scripts/colors_term.bash ~/bin          )],
      [qw( sf scripts/colors_tmux.bash ~/bin          )],
      # config
      [qw( sf  config/tmux/lay             ~/bin )],
      [qw( srf config/dotfiles/.gitignore  ~     )],
      [qw( srf config/dotfiles/.irbrc      ~     )],
      [qw( srf config/dotfiles/.pyrc       ~     )],
      [qw( srf config/dotfiles/.Xresources ~     )],
      [qw( srf config/ctags/.ctags         ~     )],
      [qw( srf config/tmux/.tmux.conf      ~     )],
   );

   foreach (@symlinks)
   {
      my ($opts, $target, $name) = @$_;

      $name =~ s@~/\.config@$ENV{XDG_CONFIG_HOME}@;
      $name =~ s/~/$ENV{HOME}/;

      # create symlink
      if ($action eq 'add')
      {
         system 'ln', "-$opts", "$ENV{REPOS_BASE}/$target", $name;
         next;
      }

      # delete symlink
      if (-d $name and not -l $name)
      {
         unlink "$name/". basename $target;
      } else {
         unlink $name;
      }
   }
}

links $ARGV[0];
