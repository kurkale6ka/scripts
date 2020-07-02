#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor ':constants';
use Getopt::Long 'GetOptions';

sub help() {
   say 'mkssh';
   exit;
}

my $stdin;
GetOptions(
   ''       => \$stdin,
   'stdin'  => \$stdin,
   'h|help' => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

if ($stdin)
{
   print 'Public key: ';
   chomp ($_ = <STDIN>);

   my @key = split;
   @key == 3 or die RED.'Wrong ssh key format. "type key email" expected'.RESET, "\n";

   my ($key, $email) = @key[1,2];
   my ($user) = split '@', $email;

   # accept name $user?
   # getent passwd $user
   # read fname lname?
   # useradd -m -s/bin/bash -c"$fname $lname" "$login"

   # # Install key
   # if mkdir -p -- "$home"/.ssh
   # then
   #    if ! grep -q "$key" "$home"/.ssh/authorized_keys 2>/dev/null
   #    then
   #       echo "Installing $_grn$login$_res's ssh key under $home/.ssh/authorized_keys..."
   #       echo "$sshkey" >> "$home"/.ssh/authorized_keys
   #    fi

   #    # Change permissions + ownership
   #    chmod 700 "$home"/.ssh
   #    chmod 600 "$home"/.ssh/authorized_keys

   #    chown -R "$login":"$login" "$home"/.ssh
   # fi
}
