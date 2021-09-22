#! /usr/bin/env perl

use v5.12;
use warnings;
use Getopt::Long qw/GetOptions :config bundling/;
use List::Util 'none';

# Help
my $help = << '------------';
ssh_config [options] <user>

--section1, -s
--XXXXXXXX
------------

# Arguments
GetOptions (
   's|section1' => \my $section1,
   'h|help'     => sub { print $help; exit }
) or die "Error in command line arguments\n";

die $help unless @ARGV;

# get user
my $user = shift;

# SSH config sections
my $sec1 = << '';
# ...
Host ss
   HostName bla.com
   User ...

my $global = << "";
# Global
# /usr/bin/ssh-add -K ~/.ssh/id_rsa # store in keychain
# /usr/bin/ssh-add -A               # add from keychain
Host *
   User $user
   AddKeysToAgent yes
   UseKeychain yes

my @sections;

if (none {defined} $section1)
{
   push @sections, $sec1;
} else {
   push @sections, $sec1 if $section1;
}

chomp (my $ssh_config = join "\n", @sections, $global);

print << "";
cat >> ~/.ssh/config << 'SSH'
$ssh_config
SSH
