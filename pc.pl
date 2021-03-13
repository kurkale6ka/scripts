#! /usr/bin/env perl

# Fuzzy password search, before copying to clipboard
#
# pass - the standard UNIX password manager
# https://www.passwordstore.org/

use v5.12;
use warnings;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $timeout = 15;
my $store = "$ENV{HOME}/.password-store";
my $copy  = $^O eq 'darwin' ? 'pbcopy'  : 'xclip';
my $paste = $^O eq 'darwin' ? 'pbpaste' : 'xclip -o';

# Help
my $help = << 'MSG';
pc [pattern] : fuzzy password search, before copying to clipboard

--stdout,  -o : show on terminal (and copy)
--store,   -s : define password store
--timeout, -t : clipboard timeout for the password
MSG

# Options
my $stdout;
GetOptions (
   'o|stdout'    => \$stdout,
   's|store=s'   => \$store,
   't|timeout=i' => \$timeout,
   'h|help'      => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

chdir $store or die RED.$!.RESET, "\n";

# Get password
if (@ARGV)
{
   $_ = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf -q"@ARGV" --read0 -0 -1 --cycle`;
} else {
   $_ = `fd -e gpg -E'*~' -0 | sed -z 's/\\.gpg\$//' | fzf --read0 -0 -1 --cycle`;
}

chomp (my $passfile = $_);

# Wait until clipboard restoration
if (my $pid = `pgrep -f pc_cb_prev`)
{
   warn RED.'Waiting for clipboard restoration...'.RESET, "\n";
   sleep 1 while kill 0, $pid;
}

# Get previous clipboard item
chomp (my $clip_prev = `$paste`);

# Copy to clipboard
if ($stdout)
{
   say YELLOW.$passfile.RESET;
   system (qw/gpg -q -d/, "$store/$passfile.gpg") == 0 or die RED.$!.RESET, "\n";
} else {
   say 'Copying ', color('yellow').$passfile.RESET, ' to the clipboard...';
}

system "gpg -q -d '$store/$passfile.gpg' | head -n1 | tr -d '\n' | $copy";
$? == 0 or die RED.$!.RESET, "\n";

# restore clipboard to previous entry
sub restore
{
   exec "echo '$clip_prev' | tr -d '\n' | $copy";
}

restore() unless $clip_prev;

# Wait in the background before restoring the clipboard
exit if my $pid = fork // die "failed to fork: $!\n";

# kid
$0 = 'pc_cb_prev';
sleep $timeout;
restore();
