#! /usr/bin/env perl

# Dot files setup
#
# run this script with:
# ---------------------
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.pl)
#
# vim-plug (after cloning):
# -------------------------
# curl -fLo ~/github/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# :PlugInstall

# TODO:
# - test create db during init
# - test init without git
# - tags(): chdir failed, propagate?

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

mkconfig              : ${YELLOW}update${RESET}
mkconfig -i           : ${YELLOW}install${RESET}
mkconfig -[u|s][l|L]t

${BOLD}OPTIONS${RESET}

--init,      -i: Initial setup
--update,    -u: Update repositories
--status,    -s: Check repositories statuses
--links,     -l: Make links
--del-links, -L: Remove links
--tags,      -t: Generate tags
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
my ($init, $update, $status, $links, $del_links, $tags);

@ARGV or $update = 1; # default action

GetOptions (
   'i|init'      => \$init,
   'u|update'    => \$update,
   's|status'    => \$status,
   'l|links'     => \$links,
   'L|del-links' => \$del_links,
   't|tags'      => \$tags,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Checks
if (@ARGV)
{
   warn RED.'Non-option arguments not allowed'.RESET, "\n";
   help;
}

if ($init and any {defined} $update, $status, $links, $del_links, $tags)
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
   say "$CYAN*$RESET Cloning repositories in $BLUE~/", basename ($ENV{REPOS_BASE}), "$RESET...";
   clone or return;

   say "$CYAN*$RESET Linking dot files";
   links 'add';

   say "$CYAN*$RESET Generating tags";
   tags;

   say "$CYAN*$RESET Creating fuzzy cd database";
   system 'bash', "$ENV{REPOS_BASE}/scripts/db-create";

   say "$CYAN*$RESET Configuring git";
   system 'bash', "$ENV{REPOS_BASE}/config/git.bash";

   # macOS
   $^O eq 'darwin' or return;

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

   system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install --HEAD neovim};
   $? == 0 or return;

   system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install slhck/moreutils/moreutils --without-parallel};
   system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install parallel --force};
   system qw{env HOMEBREW_NO_AUTO_UPDATE=1 brew install}, @formulae;
}

# private
sub clone()
{
   chdir $ENV{REPOS_BASE} or return;

   foreach my $repo (qw/zsh bash help config scripts vim/)
   {
      next if -d $repo;

      system qw/git clone/, "git\@github.com:kurkale6ka/$repo.git";
      $? == 0 or return;

      print "\n";
   }

   return 1;
}

sub update()
{
   my $action = shift;
   say 'Updating repos...';

   my @children;

   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo and chdir $repo;

      # parent
      my $pid = fork;
      defined $pid or die "failed to fork: $!";

      if ($pid)
      {
         push @children, $pid;
         next;
      }

      # kid
      system (qw/git fetch -q/) == 0 or exit;

      if (any {/^##\smaster.*behind/} `git status -b --porcelain`)
      {
         open my $pull, '-|', qw/git -c color.ui=always pull/;

         while (<$pull>)
         {
            print $CYAN. basename ($repo), "$RESET: " if 1..1;
            print;
         }
      }

      exit;
   }

   waitpid $_, 0 foreach @children;
}

sub status()
{
   my @children;

   foreach my $repo (glob "'$ENV{REPOS_BASE}/*'")
   {
      next unless -d $repo and chdir $repo;

      # parent
      my $pid = fork;
      defined $pid or die "failed to fork: $!";

      if ($pid)
      {
         push @children, $pid;
         next;
      }

      # kid
      my @status = `git status -b --show-stash --porcelain`;
      if (@status > 1 or any {/ahead|behind/} @status)
      {
         open my $st, '-|', qw/git -c color.status=always status -sb/;

         while (<$st>)
         {
            print $CYAN. basename ($repo), "$RESET: " if 1..1;
            print;
         }
      }

      exit;
   }

   waitpid $_, 0 foreach @children;
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
   ) or warn RED.'failed to generate tags'.RESET, "\n";
}
