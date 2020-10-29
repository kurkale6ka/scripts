#! /usr/bin/env perl

# Syncing of my repos folder:
#   rseverywhere [--base <...>] [--del] [--dry] destination

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config pass_through/;
use lib "$ENV{REPOS_BASE}/config/tmux";
use Nodes;

# Help
sub help() {
   my $msg = "Usage: rseverywhere [--base <...>] [--del] [--dry] destination\n";
   die $msg.Nodes::help();
}

# Arguments
my $user = 'dimitar';
my $base = 'github';
my $del;
my $dry;

GetOptions (
   'base=s' => \$base,
   'del'    => \$del,
   'dry'    => \$dry,
   'help'   => \&help,
) or die "Error in command line arguments\n";

$del = $del ? '--delete-excluded' : '--delete';
$dry = $dry ? 'n' : '';

exit unless my @hosts = nodes();

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
   # yellow?
   say $remote;

   unless (system ("ssh -TG $remote | grep 'user\\b' | grep -q $user") == 0)
   {
      $base = $user;
   }

   system
   'rsync', "-ai$dry", '--no-o', '--no-g', $del, '-e', 'ssh -q',
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

   # rsvim -ai$dry $del $ENV{REPOS_BASE}/vim $1:~/$base

   exit;
}

waitpid $_, 0 foreach @children;
