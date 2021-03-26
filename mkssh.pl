#! /usr/bin/env perl

# Install user's SSH key
#
# use this script if ssh-copy-id isn't suitable (e.g PasswordAuthentication no)
# ssh-copy-id -i ~/.ssh/id_rsa.pub user@host
#
# this script only installs the key. You still need to:
# - openssl rand -base64 25 | cut -c-20 | passwd --stdin <user>
# - AllowUsers <user>
# - systemctl reload sshd
#
# run with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkssh.pl)

use v5.12;
use warnings;
use re '/aa';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
my $help = << '-------';
mkssh [user]

-n, --dry-run : modes + ownership only (no key install)
-f, --force   : allow local install

Install user's SSH key (unless present)
* validate with ssh-keygen -lf
* create ~/.ssh/authorized_keys if needed
* enforce correct modes + ownership
-------

# Arguments
GetOptions (
   'n|dry-run' => \my $dry_run,
   'f|force'   => \my $force,
   'h|help'    => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

die $help if @ARGV > 1;

# Emit warning if trying to use this script locally
unless ($ENV{SSH_CONNECTION} or $force) {
   my $local = 1;
   open my $PIPE, '-|', 'who' or die RED.$!.RESET, "\n";
   while (<$PIPE>)
   {
      # (IP) or (:D.S) - localhost:display.screen, ref. DISPLAY
      if (/\( (?:\d{1,3}\.){3} \d{1,3} \)/x or /\( :\d(?:\.\d)? \)/x)
      {
         undef $local; last;
      }
   }
   die RED.'Attempt to run locally. Aborting!'.RESET, "\n" if $local;
}

# Get user and key
my $user = @ARGV ? shift : getpwuid $>;
my (undef, undef, $uid, $gid) = getpwnam $user;

$uid or die RED.'Wrong user'.RESET, "\n";

# Create ssh folder
mkdir glob("~$user/.ssh"), 0700;

# SSH key
unless ($dry_run)
{
   print CYAN.'Public key: '.RESET;
   chomp ($_ = <STDIN>);

   # validate
   system (qq.bash -c 'ssh-keygen -lf <(echo "$_") >/dev/null'.) == 0 or exit 1;

   my @key = split ' ', $_, 3;
   my $key = quotemeta $key[1];
   $key = qr/$key/;

   # Write key
   open my $KEYS, '+>>', glob "~$user/.ssh/authorized_keys" or die RED.$!.RESET, "\n";
   seek $KEYS, 0, 0;

   while (<$KEYS>)
   {
      next if /^\h*#/;
      die RED.'Key already installed: '.RESET.$_ if /$key/;
   }

   say $KEYS "@key";
}

# Mode + ownership
chmod 0700, glob "~$user/.ssh";
chmod 0600, glob "~$user/.ssh/authorized_keys";

chown $uid, $gid, map {glob} ("~$user/.ssh", "~$user/.ssh/authorized_keys");
