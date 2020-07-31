#! /usr/bin/env perl

# Install ssh keys in ~/.ssh/authorized_keys,
# enforce correct modes (700/600) + ownership
#
# root: create one user per key
# else: put all keys under the current user
#
# run this script with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkssh.pl)

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use File::Path 'make_path';
use Term::ReadLine;

my $BLUE  = color('ansi69');
my $CYAN  = color('ansi45');
my $GREEN = color('green');
my $S = color('bold');
my $E = color('italic');
my $R = color('reset');

# Help
sub help() {
   print <<MSG;
${S}SYNOPSIS${R}
mkssh      : read key on STDIN
mkssh ${CYAN}file${R} : read keys from file

${S}OPTIONS${R}
-d|--home-dir ${BLUE}/home${R}

${S}DESCRIPTION${R}
Install ssh keys in ${BLUE}~/.ssh/${R}authorized_keys,
enforce correct modes (700/600) + ownership

root: create one user per key
else: put all keys under the current user
MSG
exit;
}

# Arguments
my $home = $^O eq 'linux' ? '/home' : '/Users';

GetOptions(
   'd|home-dir=s' => \$home,
   'h|help'       => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

$home and $home =~ s@/$@@;

@ARGV <= 1
   or die RED.'Wrong number of arguments'.RESET, "\n";

# Declarations
sub validate_key ($);
sub install_keys (@);

# Main
unless (@ARGV)
{
   print 'Public key: ';
   chomp ($_ = <STDIN>);
   validate_key $_;
   install_keys $_;
} else {
   my @keys;
   open my $keys, '<', shift or die RED.$!.RESET, "\n";
   while (<$keys>)
   {
      next if /^#/ or /^$/;
      chomp;
      validate_key $_;
      push @keys, $_;
   }
   install_keys @keys;
}

# Functions
sub validate_key ($)
{
   $_ = shift;
   my @key = split;
   @key > 2
      or die RED.'Wrong ssh key format. "type key comment" expected'.RESET, "\n";
}

sub install_keys (@)
{
   my @keys = @_;

   # get current user
   my ($name, $passwd, $uid, $gid) = getpwuid $>;

   my $user = $name unless $name eq 'root';

   foreach my $ssh_key (@keys)
   {
      my @key = split ' ', $ssh_key;
      my $key = $key[1];

      # add user
      if ($name eq 'root')
      {
         my $comment = "@key[2..$#key]";

         if (length ($comment) < 31)
         {
            say "${CYAN}Adding user for ${GREEN}${E}$comment${R}";
         } else {
            say "${CYAN}Adding user for ${GREEN}${E}", substr ($comment, 0, 30) . "<...${R}";
         }

         # propose username from email if Perl GNU readline installed
         if ($comment =~ /@/)
         {
            my $term = Term::ReadLine->new('RL');
            $term->ornaments(0);
            $user = $term->readline ('user: ', split '@', $comment);
         } else {
            print 'user: ';
            chomp ($user = <STDIN>);
         }

         print 'comment: ';
         chomp (my $gcomment = <STDIN>);

         system qw(useradd -m -c), $gcomment, $user;
         $? == 0 or die RED.$!.RESET, "\n";

         $uid = getpwnam $user;
         $gid = getgrnam $user;
      }

      # write key
      make_path "$home/$user/.ssh";

      unless (system (qw/grep -q -s/, $key, "$home/$user/.ssh/authorized_keys") == 0)
      {
         open my $auth_keys, '>>', "$home/$user/.ssh/authorized_keys"
            or die RED.$!.RESET, "\n";
         say $auth_keys $ssh_key;
      }

      # mode and ownership
      chmod 0700, "$home/$user/.ssh";
      chmod 0600, "$home/$user/.ssh/authorized_keys";

      chown $uid, $gid, "$home/$user";
      chown $uid, $gid, "$home/$user/.ssh";
      chown $uid, $gid, "$home/$user/.ssh/authorized_keys";
   }
}
