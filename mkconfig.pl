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

my   $BLUE = color('ansi69');
my   $CYAN = color('ansi45');
my $YELLOW = color('yellow');
my   $BOLD = color('bold');
my  $RESET = color('reset');

# Repos root folder setup
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

# Help
sub help() {
   print <<MSG;
${BOLD}SYNOPSIS${RESET}

mkconfig               : ${YELLOW}update${RESET}
mkconfig -i            : ${YELLOW}install${RESET}
mkconfig -[u|s][l|L]tc

${BOLD}OPTIONS${RESET}

--init,      -i: Initial setup
--update,    -u: Update repositories
--status,    -s: Check repositories statuses
--links,     -l: Make links
--del-links, -L: Remove links
--tags,      -t: Generate tags
--cd-db,     -c: Create fuzzy cd database
MSG
exit;
}

# Declarations
sub init();
sub clone();
sub update();
sub status();
sub links($); # add|del
sub tags();

# Options
my ($status, $init, $update, $tags, $cd_db, $links, $del_links);

@ARGV or $update = 1; # update repos if no arguments

GetOptions (
   'i|init'      => \$init,
   'u|update'    => \$update,
   's|status'    => \$status,
   'l|links'     => \$links,
   'L|del-links' => \$del_links,
   't|tags'      => \$tags,
   'c|cd-db'     => \$cd_db,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Checks
# TODO: fix -sh when -s sub { say "hi" }
# add --git?
# tags(): chdir failed, propagate?
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
$init      and init;
$update    and update;
$status    and status;
$links     and links 'add';
$del_links and links 'del';
$tags      and tags;

# Subroutines
sub init()
{
   # Clone repos
   say "$CYAN*$RESET Cloning repositories in $BLUE~/", basename ($ENV{REPOS_BASE}), "$RESET...";
   clone;

   say "$CYAN*$RESET Linking dot files";
   links 'add';

   say "$CYAN*$RESET Generating tags";
   tags;

   say "$CYAN*$RESET Creating fuzzy cd database";
   system 'bash', "$ENV{REPOS_BASE}/scripts/db-create";

   say "$CYAN*$RESET Configuring git";
   system 'bash', "$ENV{REPOS_BASE}/config/git.bash";

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

      system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install}, @formulae;
      system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install --HEAD neovim};
      system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install slhck/moreutils/moreutils --without-parallel};
      system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install parallel --force};
   }
}

sub clone()
{
   chdir $ENV{REPOS_BASE} or return;

   foreach my $repo (qw/zsh bash help config scripts vim/)
   {
      unless (-d $repo)
      {
         system qw/git clone/, "git\@github.com:kurkale6ka/$repo.git";
         print "\n";
      }
   }
}

sub update()
{
   my $action = shift;
   say 'Updating repos...';

   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo and chdir $repo;

      system qw/git fetch -q/;
      if (`git symbolic-ref --short HEAD` eq 'master' and any {/behind/} `git status -b --porcelain`)
      {
         print $CYAN. basename ($repo), "$RESET: ";
         system qw/git pull/;
      }
   }
}

sub status()
{
   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo and chdir $repo;

      my @status = `git status -b --show-stash --porcelain`;
      if (@status > 1 or any {/ahead|behind/} @status)
      {
         print $CYAN. basename ($repo), "$RESET: ";
         system qw/git status -sb/;
      }
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

sub tags()
{
   # Notes:
   #   repos/zsh/autoload can't be added since the function names are 'missing'
   #   cheat by treating zsh files as sh
   chdir $ENV{REPOS_BASE} or return;

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
