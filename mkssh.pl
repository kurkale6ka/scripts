#! /usr/bin/env perl

# Install ssh keys
# TODO: read keys from file

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long 'GetOptions';
use File::Path 'make_path';
use Term::ReadLine;

my $YELLOW = color('yellow');
my   $BOLD = color('bold');
my  $RESET = color('reset');

# Help
sub help() {
   print <<MSG;
${BOLD}SYNOPSIS${RESET}
mkssh   [-d] : ${YELLOW}read DATA for keys${RESET}
mkssh - [-d] : ${YELLOW}read key on STDIN${RESET}

${BOLD}OPTIONS${RESET}
--home-dir /home, -d ...
--stdin,          -s,    -

${BOLD}DESCRIPTION${RESET}
Install ssh keys:
- add users/folders as needed
- ensure correct modes + permissions
MSG
exit;
}

# Arguments
my $stdin;
my $home = '/home';
GetOptions(
   ''             => \$stdin,
   's|stdin'      => \$stdin,
   'd|home-dir=s' => \$home,
   'h|help'       => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

die RED.'No arguments allowed'.RESET, "\n" if @ARGV;

# Declarations
sub validate_key ($);
sub install_keys (@);

# Main
if ($stdin)
{
   print 'Public key: ';
   chomp ($_ = <STDIN>);
   validate_key $_;
   install_keys $_; # how to act by default on $_?
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
         ($user) = split '@', $key[2];

         # make sure Term::ReadLine::GNU is returned
         my $term = Term::ReadLine->new('RL');
         my $user = $term->readline ('User: ', $user);

         print 'Full name: ';
         chomp (my $fname = <STDIN>);

         # getent passwd $user?
         system qw(useradd -m -c), $fname, $user;
         $? == 0 or die $!;

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

__DATA__

# keys: type key email

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUHDwFoZ8CaKSwk/Wo1EQ104EHiJ+1HBuv7CByxwues46dGbhh0oXjW7jb0g5619kcUqCGLeEdYEtEDBugwj3N5bfVTKoHsbR9RHfu9DzhnUq+FnmWtRuk8oYZ/CUjojrxcNDjdr8NhVpKIIkp/5+isco9xSSPNUa6GQOwBbrnrREKaJf2YRTWcLu+9GULcma410OrqLy6jOKxc3IfrdZEL9HO9buSotCmQFw2uTu5CS+N6jG5M90LXNpYex/ZmXSmdwDym8qZ3FSlJcfP2NYXmDLvL6SfXBE43bdtXMMcQJM8/SOzmw91YYyu2bqACXEDvr8t6nYdcUsU8b6kXuGeZrgysbi446o9+EsDjF9YGQzjMi30zcMr8luvlqE1NlfnMaMsjI10ZxtD/NMJFMSSlO84JdT0JmaDtZw9x0J/D6xlUI6K9TGrFd6T9Ae3AQ3HagsyC7nPYU18wCZQTX9V8E3IJ60JkBXOZbcvD0dcZq/c/eIzYGEGX49qGjon8GJwNVNIYMwig1FQ+vUL51euItvrG/KsMoK0JadcrKcCQ3rG0Iy74Fwamdg2bLdDElFKxam7Pi7LpWhPe/ppMUeEFQDWTtmmJFoyTyeIE0sUn/OAzJ+xe/M0uYHINbaAelXNg3rOY8ECMOuwqoT2TauYCuIP+myOqsEdsBC1gxMA6w== mitkofr@yahoo.fr
