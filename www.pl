#! /usr/bin/env perl

# fuzzy search & open of websites loaded from a file

use strict;
use warnings;
use feature 'say';
use Getopt::Long 'GetOptions';

my $sites = "$ENV{XDG_DATA_HOME}/sites";

(my $help = <<MSG) =~ s/$ENV{HOME}/~/;
www [-s sites] [pattern]
fuzzy search & open of websites ($sites)
MSG

GetOptions (
   'sites=s' => \$sites,
   'help'    => sub { print $help; exit }
) or die "Error in command line arguments\n";

-f $sites or die "No sites found\n";

if (@ARGV)
{
   $_ = `fzf -q"@ARGV" -0 -1 --cycle --height 60% < $sites`;
} else {
   $_ = `fzf -0 -1 --cycle --height 60% < $sites`;
}
chomp;

# match URLs
unless (m{ https?://\S+ }x or /www\.\S+/ or /\S+\.com\b/)
{
   my $error = $_ ? "No valid URL in: $_" : 'No match';
   die "$error\n";
}

my $site = $&;
say $site = "https://$site" unless $site =~ /\Ahttp/i;

unless ($^O eq 'darwin')
{
   exec 'xdg-open', $site;
} else {
   exec 'open', $site;
}
