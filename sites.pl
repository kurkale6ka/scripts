#! /usr/bin/env perl

# fuzzy search & open of websites loaded from a file

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;

sub help() {
   print <<MSG;
sites [-s sites] [pattern]
fuzzy search & open of websites ($ENV{XDG_DATA_HOME}/sites)
MSG
   exit;
}

my $sites;
GetOptions (
   's|sites=s' => \$sites,
   'h|help'    => \&help
) or die "Error in command line arguments\n";

$sites //= "$ENV{XDG_DATA_HOME}/sites";
-f $sites or die "No sites found\n";

if (@ARGV)
{
   $_ = `fzf -q"@ARGV" -0 -1 --cycle --height 60% < $sites`;
} else {
   $_ = `fzf -0 -1 --cycle --height 60% < $sites`;
}

chomp;
m{https?://\S+} or die "Invalid data: $_\n";

say $&;

unless ($^O eq 'darwin')
{
   system 'xdg-open', $&;
} else {
   system 'open', $&;
}
