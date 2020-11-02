#! /usr/bin/env perl

# Sync my repos to remotes

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config pass_through/;
use lib "$ENV{REPOS_BASE}/config/tmux";
use Nodes;

# Help
sub help()
{
   my $msg = << 'MSG';
Sync repos to remotes

rseverywhere @cluster ... node[range] ... [-exclude] ...

Options:
--delete-excluded
--dry

MSG
   return $msg.Nodes::help();
}

die help if @ARGV == 0;

# Arguments
my $user = 'dimitar';
my $base = 'github';
my $del;
my $dry;

GetOptions (
   'delete-excluded' => \$del,
   'dry'             => \$dry,
   'help'            => sub { print help; exit; },
) or die "Error in command line arguments\n";

$del = $del ? '--delete-excluded' : '--delete';
$dry = $dry ? 'n' : '';

# Calculate hosts
exit unless my @hosts = nodes();

sub sync($)
{
   my $remote = shift;

   unless (system ("ssh -TG $remote | grep 'user\\b' | grep -q $user") == 0)
   {
      $base = $user;
   }

   system 'rsync', "-ai$dry", '--no-o', '--no-g', $del, '-e', 'ssh -q',
   '-f', '- .git',
   '-f', '- .gitignore',
   '-f', '- LICENSE*',
   '-f', '- README*',
   '-f', '- bash/.bash_history',
   '-f', 'P bash/.bash_history',
   '-f', '- bash/.bashrc.mini',
   '-f', ".- $ENV{REPOS_BASE}/config/dotfiles/.gitignore",
   '-f', '- config/dotfiles/.inputrc.mini',
   '-f', '+ config/dotfiles/',
   '-f', '+ config/dotfiles/**',
   '-f', '- config/**',
   '-f', '+ scripts/db-create',
   '-f', '+ scripts/pg.pl',
   '-f', '+ scripts/mkconfig.sh',
   '-f', '- scripts/**',
   '-f', '- zsh/after/ssh.alt',
   "$ENV{REPOS_BASE}/fzf",
   "$ENV{REPOS_BASE}/bash",
   "$ENV{REPOS_BASE}/config",
   "$ENV{REPOS_BASE}/scripts",
   "$ENV{REPOS_BASE}/zsh",
   "$remote:~/$base";

   # Vim repo sync

   # -f':- .gitignore' can't be used, as this way we also exclude patterns from
   # the plugins .gitignore files and that is too much. also, .gitignore might
   # include peculiar patterns like !plugged/vsearch

   # local check for CSApprox plugin
   if (-d "$ENV{REPOS_BASE}/vim/plugged/csapprox")
   {
      system 'rsync', "-ai$dry", '--no-o', '--no-g', $del, '-e', 'ssh -q',
      '-f', '- .git',
      '-f', '- .gitignore',
      '-f', ".- $ENV{REPOS_BASE}/config/dotfiles/.gitignore",
      '-f', ". $ENV{REPOS_BASE}/vim/extra/excludes",
      "$ENV{REPOS_BASE}/vim",
      "$remote:~/$base";
   }
   else
   {
      warn << 'MSG';
The CSApprox plugin folder is missing. Please run the following in Vim:
Plug 'godlygeek/csapprox'|PlugInstall
MSG
   }
}

# Single host
if (@hosts == 1)
{
   sync shift;
   exit;
}

# Multiple hosts
my @children;

foreach my $remote (@hosts)
{
   # parent
   my $pid = fork // die "failed to fork: $!";

   if ($pid)
   {
      push @children, $pid;
      next;
   }

   # kid
   say $remote;
   sync $remote;

   exit;
}

waitpid $_, 0 foreach @children;
