#! /usr/bin/env perl

# Fuzzy search and copy of passwords
#
# pass - the standard UNIX password manager
# https://www.passwordstore.org/

use v5.12;
use warnings;
use POSIX ':sys_wait_h';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $store = "$ENV{HOME}/.password-store";

# Help
my $help = << '';
Fuzzy search and copy of passwords
pc [-s store] [-o|--stdout] [pattern] ... : copy password

# Arguments
my $stdout;
GetOptions (
   's|store=s' => \$store,
   'o|stdout'  => \$stdout,
   'h|help'    => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

chdir $store or die RED.$!.RESET, "\n";

# Get password
my $pfile;
if (@ARGV)
{
   $pfile = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf -q"@ARGV" --read0 -0 -1 --cycle`;
} else {
   $pfile = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf --read0 -0 -1 --cycle`;
}

chomp $pfile;

# Speed up previous clipboard restoration
if (my $pid = `pgrep -f pc_cb_prev`)
{
   kill 'TERM', $pid or die RED.'Failed to kill'.RESET, "\n";
}

# Get previous clipboard item
my $paste = $^O eq 'darwin' ? 'pbpaste' : 'xclip -o';
# base64 encode to obfuscate password in 'ps'
chomp (my $clip_prev = `$paste | openssl base64`);

# Copy to clipboard
if ($stdout)
{
   say YELLOW.$pfile.RESET;
   system (qw/gpg -q -d/, "$store/$pfile.gpg") == 0 or die RED.$!.RESET, "\n";
} else {
   say 'Copying ', color('yellow').$pfile.RESET, ' to the clipboard...';
}

system "gpg -q -d $store/$pfile.gpg | head -n1 | tr -d '\n' | pbcopy";
$? == 0 or die RED.$!.RESET, "\n";

# Wait in the background before restoring the clipboard
exit if my $pid = fork // die "failed to fork: $!\n";

# kid
# keep password for 45sec, then reset clipboard to previous entry
$0 = 'pc_cb_prev';
sleep 45;

# reset clipboard to previous entry
exec "echo $clip_prev | openssl base64 -d | pbcopy";
