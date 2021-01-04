#! /usr/bin/env perl

# - create ssh folder, check sshd_config?
# - get/validate/install keys
# - change permissions
# - reload ssh? check messages, secure?

# non root
# get key
# display permissions, namei, other info?

# Install ssh key in ~/.ssh/authorized_keys,
#
# run this script with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkssh.pl)

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
my $help = << 'MSG';
mkssh <user>
append key to ~/.ssh/authorized_keys
- check/fix modes
- get fingerprint?
MSG

# Arguments
GetOptions(
   'h|help' => sub {print $help; exit}
) or die RED.'Error in command line arguments'.RESET, "\n";

@ARGV == 1 or die $help;

my $user = shift;
my $uid = getpwnam $user;

# Main
print CYAN.'Public key: '.RESET;
chomp ($_ = <STDIN>);

system ("echo '$_' | ssh-keygen -lf - >/dev/null") == 0 or die RED.$!.RESET, "\n";

my @key = split ' ', $_, 3;
my $key = quotemeta $key[1];
$key = qr/$key/;

# local/remote differentiation ...
mkdir glob("~$user/.ssh"), 0700;

# Write key
# todo: skip if local
open my $KEYS, '+>>', glob "~$user/.ssh/authorized_keys" or die RED.$!.RESET, "\n";
seek $KEYS, 0, 0;

while (<$KEYS>) {
   die RED.'Key already installed: '.RESET.$_ if /$key/;
}

say $KEYS "@key";

# Set mode + ownership
# todo: print changes, get mode first
chmod 0600, glob "~$user/.ssh/authorized_keys";

chown $uid, -1, glob "~$user";
chown $uid, -1, glob "~$user/.ssh";
chown $uid, -1, glob "~$user/.ssh/authorized_keys";
