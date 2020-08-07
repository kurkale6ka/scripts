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

my $YELLOW = color('YELLOW');
my $R = color('reset');

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

chomp $pfile;

# kill any 'restore clipboard' processes
system qw/pkill -f pc_cb_prev/
   or die RED."$!".RESET, "\n";

my $clip_prev;

# Get previous clipboard item
unless ($^O eq 'darwin')
{
   # base64 encode to obfuscate password in 'ps'
   $clip_prev = `xclip -o | openssl base64`;
} else {
   $clip_prev = `pbpaste | openssl base64`;
}

chomp $clip_prev;
say $clip_prev;

# Copy to clipboard
if ($stdout)
{
   say YELLOW, $pfile, RESET;
   system qw/gpg -q -d/, "$store/$pfile.gpg"
      or die RED."$!".RESET, "\n";
} else {
   say "Copying ${YELLOW}$pfile${R} to the clipboard...";
}

system "gpg -q -d $store/$pfile.gpg | head -n1 | tr -d '\n' | pbcopy"
   or die RED."$!".RESET, "\n";

my $pid = fork // die "failed to fork: $!";

# kid
# keep password for 45sec, then reset clipboard to previous entry
if ($pid == 0)
{
   say "KID";
   $0 = 'pc_cb_prev';

   sleep 5;

   # reset clipboard to previous entry
   system "echo $clip_prev | openssl base64 -d | pbcopy"
      or die RED."$!".RESET, "\n";

   exit;
}

waitpid $pid, WNOHANG;
