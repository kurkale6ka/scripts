#! /usr/bin/env perl

# Fuzzy search and copy of passwords
#
# pass - the standard UNIX password manager
# https://www.passwordstore.org/

use strict;
use warnings;
use autodie;
use feature 'say';
use POSIX ":sys_wait_h";
use File::Glob ':bsd_glob';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $store = glob '~/.password-store';

# Help
sub help() {
   print << 'MSG';
Fuzzy search and copy of passwords
pc [-s store] [-o|--stdout] [pattern] ... : copy password
MSG
   exit;
}

# Arguments
my $stdout;
GetOptions (
   's|store=s' => \$store,
   'o|stdout'  => \$stdout,
   'h|help'    => \&help
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

system qw/pkill pc_cb_prev/;

my $clip_prev = `pbpaste`;

open my $paste, '|-', 'pbcopy';

print $paste $pfile;
# gpg -q -d $pstore/$pfile.gpg | head -n1 | tr -d '\n' | xclip

my $pid = fork;

# kid
if ($pid == 0)
{
   $0 = 'pc_cb_prev';

   sleep 5;

   print $paste $clip_prev;
   exit;
}

waitpid $pid, WNOHANG;
