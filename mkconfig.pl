#! /usr/bin/env perl

# run this script with:
# ---------------------
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.pl)
#
# vim-plug (after cloning):
# -------------------------
# curl -fLo ~/github/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# :PlugInstall

use strict;
use warnings;
use feature 'say';
use File::Path 'make_path';
use File::Basename qw/dirname basename/;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;
use List::Util 'any';

my  $BLUE = color('ansi69');
my  $CYAN = color('ansi45');
my  $BOLD = color('bold');
my $RESET = color('reset');

unless ($ENV{REPOS_BASE})
{
   warn RED.'REPOS_BASE empty'.RESET, "\n";
   print "define or accept default [$BLUE~/github$RESET]: ";

   chomp ($ENV{REPOS_BASE} = <STDIN>);

   $ENV{REPOS_BASE} ||= '~/github';
   $ENV{REPOS_BASE} =~ s/~/$ENV{HOME}/;

   if (-d dirname $ENV{REPOS_BASE})
   {
      make_path $ENV{REPOS_BASE};
   } else {
      die RED."parent folder doesn't exist".RESET, "\n";
   }

   print "\n";
}

sub help() {
   print <<MSG;
${BOLD}SYNOPSIS${RESET}
mkconfig
${BOLD}OPTIONS${RESET}
--init,      -i: Initial setup
--status,    -s: Check repositories statuses
--update,    -u: Update repositories
--tags,      -t: Generate tags
--cd-db,     -c: Create fuzzy cd database
--links,     -l: Make links
--del-links, -L: Remove links
MSG
}

sub init();
sub repos($); # status|update
sub tags();
sub links($); # add|del

# Options
my ($status, $init, $update, $tags, $cd_db, $links, $del_links);

@ARGV or $update = 1;

GetOptions (
   's|status'    => \$status,
   'i|init'      => \$init,
   'u|update'    => \$update,
   't|tags'      => \$tags,
   'c|cd-db'     => \$cd_db,
   'l|links'     => \$links,
   'L|del-links' => \$del_links,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Checks
# TODO: help alone
# speed: parallel, open...
# test with git, brew, not installed
if ($init and any {defined} $status, $update, $tags, $cd_db, $links, $del_links)
{
   die RED.'--init must be used on its own'.RESET, "\n";
}

if ($status and $update)
{
   $update = 0;
   warn YELLOW.'--status and --update (ignored) are mutually exclusive'.RESET, "\n";
}

if ($links and $del_links)
{
   die RED.'--links and --del-links are mutually exclusive'.RESET, "\n";
}

# XDG setup
make_path ($ENV{XDG_CONFIG_HOME} //= "$ENV{HOME}/.config");
make_path (  $ENV{XDG_DATA_HOME} //= "$ENV{HOME}/.local/share");

# Actions
$status    and repos 'status';
$init      and init;
$update    and repos 'update';
$tags      and tags;
$links     and links 'add';
$del_links and links 'del';

# Subroutines

sub init()
{
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
   system "$ENV{REPOS_BASE}/config/git.bash";

   say "$CYAN*$RESET Linking dot files";
   links 'add';

   say "$CYAN*$RESET Generating tags";
   tags;

   say "$CYAN*$RESET Creating fuzzy cd database";
   system "$ENV{REPOS_BASE}/scripts/db-create";

   if ($^O eq 'darwin')
   {
      say "$CYAN*$RESET Installing Homebrew formulae...";

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
      system qw/brew install/, '--HEAD neovim';
      system qw/brew install/, 'slhck/moreutils/moreutils --without-parallel';
      system qw/brew install/, 'parallel --force';

      # Fix Homebrew PATHs
      # path=("$(brew --prefix coreutils)"/libexec/gnubin $path)
      # typeset -Ug path
   }
}

sub repos($)
{
   my $action = shift;
   $action eq 'update' and say 'Updating repos...';

   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo;
      if (chdir $repo)
      {
         if ($action eq 'status')
         {
            if (`git status --porcelain` or any {/]$/} `git status -sb`)
            {
               print $CYAN. basename ($repo), "$RESET: ";
               system qw/git status -sb/;
            }
         } else {
            system qw/git fetch -q/;
            if (`git symbolic-ref --short HEAD` eq 'master' and any {/behind/} `git status -sb`)
            {
               print $CYAN. basename ($repo), "$RESET: ";
               system qw/git pull/;
            }
         }
      }
   }
}

sub tags()
{
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
