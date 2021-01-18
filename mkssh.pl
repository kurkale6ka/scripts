#! /usr/bin/env perl

# Append SSH key to ~/.ssh/authorized_keys
#
# if PasswordAuthentication yes, use:
# ssh-copy-id -i ~/.ssh/id_rsa.pub user@host
#
# This script only installs the key. You still need to:
# - openssl rand -base64 25 | cut -c-20 | passwd --stdin <user>
# - AllowUsers <user>
# - systemctl reload sshd
#
# run this script with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkssh.pl)

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
my $help = << 'MSG';
mkssh [user]
append key to ~/.ssh/authorized_keys
MSG

# Arguments
GetOptions(
   'h|help' => sub {print $help; exit}
) or die RED.'Error in command line arguments'.RESET, "\n";

die $help if @ARGV > 1;

# Emit warning if trying to use this script locally
unless ($ENV{SSH_CONNECTION}) {
   my $local = 1;
   open my $pipe, '-|', 'who' or die RED.$!.RESET, "\n";
   while (<$pipe>) {
      if (/\( (?:\d{1,3}\.){3} \d{1,3} \)/x or /\( :\d\.\d \)/x) { # (IP) or (:D.S) - localhost:display.screen, ref. DISPLAY
         undef $local; last;
      }
   }
   die RED.'Attempt to run locally. Aborting!'.RESET, "\n" if $local;
}

# Get user and key
my $user = @ARGV ? shift : getpwuid $>;

my $uid = getpwnam $user or die RED.'Wrong user'.RESET, "\n";
my $gid = getgrnam $user;

print CYAN.'Public key: '.RESET;
chomp ($_ = <STDIN>);

# check key
system ("echo '$_' | ssh-keygen -lf - >/dev/null") == 0 or exit 1;

my @key = split ' ', $_, 3;
my $key = quotemeta $key[1];
$key = qr/$key/;

# Create ssh folder
mkdir glob("~$user/.ssh"), 0700;

# Write key
open my $KEYS, '+>>', glob "~$user/.ssh/authorized_keys" or die RED.$!.RESET, "\n";
seek $KEYS, 0, 0;

while (<$KEYS>) {
   next if /^\h*#/;
   die RED.'Key already installed: '.RESET.$_ if /$key/;
}

say $KEYS "@key";

# Set mode
chmod 0600, glob "~$user/.ssh/authorized_keys";

# Set ownership
chown $uid, $gid, map glob, ("~$user/.ssh", "~$user/.ssh/authorized_keys");
