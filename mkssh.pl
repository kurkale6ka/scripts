#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor ':constants';
use Getopt::Long 'GetOptions';
use File::Path 'make_path';
# use Term::ReadLine;

sub help() {
   say 'mkssh';
   exit;
}

my $stdin;
GetOptions(
   ''      => \$stdin,
   'stdin' => \$stdin,
   'help'  => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Install key
sub install_key # ($$)
{
   my ($key, $user) = @_;
   my ($name, $passwd, $uid, $gid) = getpwuid $<;

   $user = $name unless $name eq 'root';

   make_path "/tmp/$user/.ssh";

   unless (system ('grep', '-s', $key, "/tmp/$user/.ssh/authorized_keys") == 0)
   {
      open my $auth_keys, '>>', "/tmp/$user/.ssh/authorized_keys";
      # say "Installing $_grn$login$_res's ssh key under $home/.ssh/authorized_keys..."
      # TODO: write all key components
      say $auth_keys $key;
   }

   chmod 0700, "/tmp/$user/.ssh";
   chmod 0600, "/tmp/$user/.ssh/authorized_keys";

   chown $uid, $gid, "/tmp/$user/.ssh";
}

#  in: ssh key
# out: key + user guess from the key's comment
sub read_key ($)
{
   $_ = shift;

   my @key = split;
   @key == 3 or die RED.'Wrong ssh key format. "type key email" expected'.RESET, "\n";

   my ($key, $email) = @key[1,2];
   my ($user) = split '@', $email;

   return ($key, $user);
}

if ((getpwuid $<)[0] eq 'root')
{
   # getent passwd $user
   # read fname lname

   # Accept name $user?
   # make sure Term::ReadLine::GNU is returned
   # my $term = Term::ReadLine->new();
   # $term->readline ('User', $user);

   # system qw(useradd -m -s/bin/bash -c), "$fname $lname", "$user";
}

if ($stdin)
{
   print 'Public key: ';
   chomp ($_ = <STDIN>);

   # how to act by default on $_?
   install_key (read_key $_);
} else {
   while (<DATA>)
   {
      next if /^#/ or /^$/;
      install_key (read_key $_);
   }
}

__DATA__

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUHDwFoZ8CaKSwk/Wo1EQ104EHiJ+1HBuv7CByxwues46dGbhh0oXjW7jb0g5619kcUqCGLeEdYEtEDBugwj3N5bfVTKoHsbR9RHfu9DzhnUq+FnmWtRuk8oYZ/CUjojrxcNDjdr8NhVpKIIkp/5+isco9xSSPNUa6GQOwBbrnrREKaJf2YRTWcLu+9GULcma410OrqLy6jOKxc3IfrdZEL9HO9buSotCmQFw2uTu5CS+N6jG5M90LXNpYex/ZmXSmdwDym8qZ3FSlJcfP2NYXmDLvL6SfXBE43bdtXMMcQJM8/SOzmw91YYyu2bqACXEDvr8t6nYdcUsU8b6kXuGeZrgysbi446o9+EsDjF9YGQzjMi30zcMr8luvlqE1NlfnMaMsjI10ZxtD/NMJFMSSlO84JdT0JmaDtZw9x0J/D6xlUI6K9TGrFd6T9Ae3AQ3HagsyC7nPYU18wCZQTX9V8E3IJ60JkBXOZbcvD0dcZq/c/eIzYGEGX49qGjon8GJwNVNIYMwig1FQ+vUL51euItvrG/KsMoK0JadcrKcCQ3rG0Iy74Fwamdg2bLdDElFKxam7Pi7LpWhPe/ppMUeEFQDWTtmmJFoyTyeIE0sUn/OAzJ+xe/M0uYHINbaAelXNg3rOY8ECMOuwqoT2TauYCuIP+myOqsEdsBC1gxMA6w== dimitar.dimitrov@theengagehub.com
