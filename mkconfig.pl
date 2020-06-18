#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use File::Path 'make_path';
use File::Basename 'basename';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;

my $BLUE = color('ansi69');
my $CYAN = color('ansi45');
my $RESET = color('reset');

sub help
{
   print <<MSG;
-i: Initial setup
-s: Check repositories statuses
-u: Update repositories
-t: Generate tags
-c: Create fuzzy cd database
-l: Make links
-L: Remove links
MSG
}

sub init;
sub repos($); # status|update
sub mktags;
sub links($); # add|del

# Options
my ($links, $del_links);

GetOptions (
   's|status'    => sub { repos 'status'; exit },
   'i|init'      => sub {          &init; exit },
   'u|update'    => \&repos ('update'),
   't|tags'      => \&mktags,
   'c|gen-c-db'  => \&db_create,
   'l|links'     => \$links,
   'L|del-links' => \$del_links,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

if ($links and $del_links)
{
   die RED.'--links and --del-links are mutually exclusive'.RESET, "\n";
}
$links     and links 'add';
$del_links and links 'del';

sub init
{
   if ($^O ne 'darwin')
   {
      my @formulae = qw(
      bash
      zsh
      shellcheck
      ed
      gnu-sed
      gawk
      vim
      fd
      findutils
      coreutils
      grep
      ripgrep
      mariadb
      sqlite
      colordiff
      bat
      git
      ctags
      gnu-tar
      iproute2mac
      tcpdump
      telnet
      tmux
      weechat
      tree
      gcal
      nmap
      dos2unix
      wgetpaste
      );

      system qw/brew install/, @formulae;
      # push @formulae, '--HEAD neovim';
      # push @formulae, 'slhck/moreutils/moreutils --without-parallel';
      # push @formulae, 'parallel --force';
   }

   make_path $ENV{REPOS_BASE};

   # Clone repos
   if (chdir $ENV{REPOS_BASE})
   {
      say "$CYAN*$RESET Cloning repositories in $BLUE~/", basename ($ENV{REPOS_BASE}), "$RESET...";
      foreach my $repo (qw/zsh bash help config scripts vim/)
      {
         unless (-d $repo)
         {
            system qw/git clone/, "git\@github.com:kurkale6ka/$repo.git";
            print "\n";
         }
      }
   }

   say "$CYAN*$RESET Configuring git";
   # . $REPOS_BASE/config/git.bash

   # XDG setup
   # . $REPOS_BASE/zsh/.zshenv

   say "$CYAN*$RESET Linking dot files";
   links 'add';

   say "$CYAN*$RESET Generating tags";
   mktags;

   say "$CYAN*$RESET Creating fuzzy cd database";
   # . $REPOS_BASE/scripts/db-create
}

sub repos($)
{
   my $action = shift;

   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo;
      if (chdir $repo)
      {
         if ($action eq 'status')
         {
            # if [[ -n $(git status --porcelain) ]] || git status -sb | grep -qE ']$'
            # then
            #    print -nP "%F{45}${repo:t}%f: "
            #    git status -sb
            # fi
         } else {
            # git fetch -q
            # if [[ $(git symbolic-ref --short HEAD) == master ]] && git status -sb | grep -q behind
            # then
            #    print -nP "%F{45}${repo:t}%f: "
            #    git pull
            # fi
         }
      }
   }
}

sub mktags
{
   unless ($ENV{XDG_CONFIG_HOME})
   {
      warn RED.'XDG setup needed'.RESET, "\n";
      return;
   }

   # Notes:
   #   repos/zsh/autoload can't be added since the function names are 'missing'
   #   cheat by treating zsh files as sh
   if (chdir $ENV{REPOS_BASE})
   {
      open (my $tags, '-|', 'ctags', '-R',
         "--langmap=vim:+.vimrc,sh:+.after",
         "--exclude='*~ '",
         "--exclude='.*~'",
         "--exclude=plugged",
         "--exclude=colors",
         "--exclude=keymap",
         "--exclude=plug.vim",
         "$ENV{XDG_CONFIG_HOME}/zsh",
         "$ENV{REPOS_BASE}/scripts",
         "$ENV{REPOS_BASE}/vim",
         "$ENV{REPOS_BASE}/vim/plugged/vsearch",
         "$ENV{REPOS_BASE}/vim/plugged/vim-blockinsert",
         "$ENV{REPOS_BASE}/vim/plugged/vim-chess",
         "$ENV{REPOS_BASE}/vim/plugged/vim-desertEX",
         "$ENV{REPOS_BASE}/vim/plugged/vim-pairs",
         "$ENV{REPOS_BASE}/vim/plugged/vim-swap",
      ) or die RED.'failed to generate tags'.RESET, "\n";
   }
}

sub links($)
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
