#! /usr/bin/env perl

# fuzzy search & open of websites loaded from a file

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;

sub help() {
   print <<MSG;
Fuzzy search & open of websites loaded from a file
$0 [-s sites] [pattern]
MSG
exit;
}

my $sites;

GetOptions (
   's|sites=s' => \$sites,
   'h|help'    => \&help
) or die "Error in command line arguments\n";

$sites or die "No sites found\n";

if (@ARGV)
{
   $_ = `fzf -q"@ARGV" -0 -1 --cycle --height 60% < $sites`;
} else {
   $_ = `fzf -0 -1 --cycle --height 60% < $sites`;
}

chomp;
m{https?://\S+} or die "Invalid data: $_\n";

say $&;
system 'open', $&;
