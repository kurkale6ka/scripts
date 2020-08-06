#! /usr/bin/env perl

# Fuzzy search and copy of passwords
#
# pass - the standard UNIX password manager
# https://www.passwordstore.org/

use strict;
use warnings;
use feature 'say';
use POSIX ":sys_wait_h";
use File::Glob ':bsd_glob';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use File::Basename 'basename';
use File::Path 'make_path';
use List::Util 'any';

my $store = glob '~/.password-store';

my $BLUE = color('ansi69');
my $CYAN = color('ansi45');
my $S = color('bold');
my $R = color('reset');

# Help
sub help() {
   print << 'MSG';
Fuzzy search and copy of passwords
pc [-o|--stdout] [pattern] ... : copy password
MSG
   exit;
}

# Arguments
my $stdout;
GetOptions (
   's|store'  => \$store,
   'o|stdout' => \$stdout,
   'h|help'   => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

chdir $store;

my $pfile;

# Get password
if (@ARGV)
{
   $pfile = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf -q"@ARGV" --read0 -0 -1 --cycle`;
} else {
   $pfile = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf --read0 -0 -1 --cycle`;
}

system qw/pkill -f pc_cb_previous/;

my $clip_prev = `pbpaste`;

my $pid = fork // die "failed to fork: $!";

# kid
if ($pid == 0)
{
   $0 = 'pc_cb_previous';
   sleep 45;
   say "Hello World";
   exit;
}

say $pfile;
waitpid $pid, WNOHANG;
