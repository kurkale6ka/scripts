#! /usr/bin/env perl

# fuzzy search & open of websites loaded from a file

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;

my $sites = "$ENV{XDG_DATA_HOME}/sites";

sub help() {
   print <<MSG;
www [-s sites] [pattern]
fuzzy search & open of websites ($ENV{XDG_DATA_HOME}/sites)
MSG
   exit;
}

GetOptions (
   's|sites=s' => \$sites,
   'h|help'    => \&help
) or die "Error in command line arguments\n";

-f $sites or die "No sites found\n";

if (@ARGV)
{
   $_ = `fzf -q"@ARGV" -0 -1 --cycle --height 60% < $sites`;
} else {
   $_ = `fzf -0 -1 --cycle --height 60% < $sites`;
}
chomp;

unless (m{https?://\S+})
{
   my $error = $_ ? "No valid URL in: $_" : 'No match';
   die "$error\n";
}

say $&;

unless ($^O eq 'darwin')
{
   exec 'xdg-open', $&;
} else {
   exec 'open', $&;
}
