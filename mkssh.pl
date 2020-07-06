#! /usr/bin/env perl

# Install ssh keys in ~/.ssh/authorized_keys
# enforce correct modes (700/600) + ownership
#
# as root, create one user per key,
# else put all keys under the current user
#
# run this script with:
# perl <(curl -s https://raw.githubusercontent.com/kurkale6ka/scripts/master/mkssh.pl) -

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use File::Path 'make_path';
use Term::ReadLine;

my $B = color('ansi69');
my $C = color('ansi45');
my $G = color('green');
my $Y = color('yellow');
my $S = color('bold');
my $E = color('italic');
my $R = color('reset');

# Help
sub help() {
   print <<MSG;
${S}SYNOPSIS${R}
mkssh         [-d ${B}/home${R}] : ${Y}read key on STDIN${R}
mkssh -f file [-d ${B}/home${R}] : ${Y}read keys from file${R}

--home-dir /home, -d ...

${S}DESCRIPTION${R}
Install ssh keys in ${B}~/.ssh/${R}authorized_keys
enforce correct modes (700/600) + ownership

as root, create one user per key,
else put all keys under the current user
MSG
exit;
}

# Arguments
my $stdin;
my $home = '/home';
GetOptions(
   'd|home-dir=s' => \$home,
   'h|help'       => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

@ARGV <= 1 or
die RED.'Wrong number of arguments: mkssh [-f file] [-d]'.RESET, "\n";

# Declarations
sub validate_key ($);
sub install_keys (@);

# Main
if ($stdin)
{
   print 'Public key: ';
   chomp ($_ = <STDIN>);
   validate_key $_;
   install_keys $_;
} else {
   my @keys;
   while (<DATA>)
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
   @key == 3 or die RED.'Wrong ssh key format. "type key email" expected'.RESET, "\n";
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
         my $comment = $key[2];
         say "${C}Adding user for ${G}${E}$comment${R}";

         # propose username from email if Perl GNU readline installed
         if ($comment =~ /@/)
         {
            my $term = Term::ReadLine->new('RL');
            $term->ornaments(0);
            $user = $term->readline ('User: ', split '@', $comment);
         } else {
            print 'User: ';
            chomp ($user = <STDIN>);
         }

         print 'Comment: ';
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
         open my $auth_keys, '>>', "$home/$user/.ssh/authorized_keys";
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
