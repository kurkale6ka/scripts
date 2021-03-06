#! /usr/bin/env perl

# Dot files setup
# ---------------
#
# run this script with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkconfig.pl) -h

use v5.26;
use warnings;
use File::Glob ':bsd_glob';
use File::Path 'make_path';
use File::Basename qw/dirname basename/;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;
use List::Util qw/any all/;

my $BLUE   = color 'ansi69';
my $CYAN   = color 'ansi45';
my $YELLOW = color 'yellow';
my $S = color 'bold';
my $R = color 'reset';

# Variables and declarations
my $user = 'kurkale6ka';

my @repos = qw(
bash
config
help
scripts
vim
zsh
);

my $plugins = 'vim/plugged';
my @plugins = qw(
vim-blockinsert
vim-chess
vim-desertEX
vim-pairs
vim-swap
);

sub init();
sub checkout();
sub update();
sub status();
sub links($); # add|del
sub tags();

# Options
my ($init, $download, $update, $status, $links, $del_links, $tags, $long_help);

@ARGV or $update = 1; # default action

GetOptions (
   'i|init'      => \$init,
   'd|download'  => \$download,
   'u|update'    => \$update,
   's|status'    => \$status,
   'l|links'     => \$links,
   'L|del-links' => \$del_links,
   't|tags'      => \$tags,
   'H|long-help' => \$long_help,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Repos root folder setup
unless ($ENV{REPOS_BASE})
{
   warn RED.'Repositories root undefined'.RESET, "\n";
   print "define or accept default [$BLUE~/github$R]: ";

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

my $vim_help = << "";
${CYAN}to install vim-plug${R}:
curl -fLo $ENV{REPOS_BASE}/vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
REPOS_BASE=$ENV{REPOS_BASE} vim -c PlugInstall

# Help
sub help()
{
   print <<~ "MSG";
   ${S}SYNOPSIS${R}

   mkconfig              : ${YELLOW}update${R}
   mkconfig -i[d]        : ${YELLOW}install${R}
   mkconfig -[u|s][l|L]t

   ${S}OPTIONS${R}

   --init,      -i: Initial setup
   --download,  -d: Download repositories vs checkout
   --update,    -u: Update repositories
   --status,    -s: Check repositories statuses
   --links,     -l: Make links
   --del-links, -L: Remove links
   --tags,      -t: Generate tags
   --long-help, -H: Long help
   MSG

   print "\n$vim_help" if $long_help;
   exit;
}

help if $long_help;

# More checks
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
   say "$CYAN*$R Checking out repositories in ${BLUE}$ENV{REPOS_BASE}${R}...";
   checkout or return;

   say "$CYAN*$R Linking dot files";
   links 'add';

   say "$CYAN*$R Generating tags";
   tags;

   say "$CYAN*$R Creating fuzzy cd database";
   system 'bash', "$ENV{REPOS_BASE}/scripts/db-create";

   say "$CYAN*$R Configuring git";
   system 'bash', "$ENV{REPOS_BASE}/config/git.bash";

   # macOS
   $^O eq 'darwin' or return;

   say "$CYAN*$R Installing Homebrew formulae...";

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
sub checkout()
{
   chdir $ENV{REPOS_BASE} or return;

   my @children;
   my @statuses;

   foreach my $repo (@repos, @plugins)
   {
      next if -d $repo;

      # parent
      my $pid = fork // die "failed to fork: $!";

      if ($pid)
      {
         push @children, $pid;
         next;
      }

      # kid
      unless ($download)
      {
         system qw/git clone/, "git\@github.com:$user/$repo.git";
      } else {
         system qw/git clone/, "https://github.com/$user/$repo.git";
      }

      unless ($? == 0)
      {
         push @statuses, -1;
         die RED.$!.RESET, "\n";
      }

      push @statuses, 0;
      print "\n" unless $download;
      exit;
   }

   waitpid $_, 0 foreach @children;

   if (all {$_ == 0} @statuses)
   {
      system ('mv', @plugins, $plugins) == 0 or die RED.$!.RESET, "\n";
      say $vim_help;
      return 1;
   } else {
      return 0;
   }
}

sub update()
{
   say 'Updating repos...';

   my @children;

   foreach my $repo (@repos, map {"$plugins/$_"} @plugins)
   {
      next unless -d "$ENV{REPOS_BASE}/$repo" and chdir "$ENV{REPOS_BASE}/$repo";

      # parent
      my $pid = fork // die "failed to fork: $!";

      if ($pid)
      {
         push @children, $pid;
         next;
      }

      # kid
      system (qw/git fetch -q/) == 0 or exit;

      if (any {/^##\smaster.*behind/} `git status -b --porcelain`)
      {
         my $name = basename $repo;
         my $status = `git -c color.ui=always pull`;
         print "${CYAN}$name${R}: $status";
      }

      exit;
   }

   waitpid $_, 0 foreach @children;
}

sub status()
{
   my @children;

   foreach my $repo (@repos, map {"$plugins/$_"} @plugins)
   {
      next unless -d "$ENV{REPOS_BASE}/$repo" and chdir "$ENV{REPOS_BASE}/$repo";

      # parent
      my $pid = fork // die "failed to fork: $!";

      if ($pid)
      {
         push @children, $pid;
         next;
      }

      # kid
      my @status = `git status -b --show-stash --porcelain`;

      if (@status > 1 or any {/ahead|behind/} @status)
      {
         my $name = basename $repo;
         my $status = `git -c color.status=always status -sb`;
         print "${CYAN}$name${R}: $status";
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
      [qw( sf scripts/backup.pl        ~/bin/b            )],
      [qw( sf scripts/ex.pl            ~/bin/ex           )],
      [qw( sf scripts/calc.pl          ~/bin/calc         )],
      [qw( sf scripts/cert.pl          ~/bin/cert         )],
      [qw( sf scripts/mkconfig.pl      ~/bin/mkconfig     )],
      [qw( sf scripts/mini.pl          ~/bin/mini         )],
      [qw( sf scripts/pics.pl          ~/bin/pics         )],
      [qw( sf scripts/rseverywhere.pl  ~/bin/rseverywhere )],
      [qw( sf scripts/colors_term.bash ~/bin              )],
      [qw( sf scripts/colors_tmux.bash ~/bin              )],
      # config
      [qw( sf  config/tmux/lay.pl          ~/bin/lay   )],
      [qw( sf  config/tmux/Nodes.pm        ~/bin/nodes )],
      [qw( srf config/dotfiles/.gitignore  ~           )],
      [qw( srf config/dotfiles/.irbrc      ~           )],
      [qw( srf config/dotfiles/.pyrc       ~           )],
      [qw( srf config/dotfiles/.Xresources ~           )],
      [qw( srf config/ctags/.ctags         ~           )],
      [qw( srf config/tmux/.tmux.conf      ~           )],
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
      "scripts",
      "vim",
      map {"$plugins/$_"} 'vsearch', @plugins,
   ) or warn RED.'failed to generate tags'.RESET, "\n";
}
