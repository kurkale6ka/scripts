#! /usr/bin/env perl

# Fuzzy search & open of websites loaded from a file

use v5.14;
use warnings;
use Getopt::Long 'GetOptions';

my $sites = "$ENV{XDG_DATA_HOME}/sites";

my $help = << "" =~ s/$ENV{HOME}/~/r;
www [-s sites] [pattern]
fuzzy search & open of websites ($sites)

GetOptions (
   'sites=s' => \$sites,
   'help'    => sub { print $help; exit }
) or die "Error in command line arguments\n";

-f $sites or die "No sites found\n";

if (@ARGV)
{
   s/'/'"'"'/g foreach @ARGV;
   $_ = `fzf -q'@ARGV' -0 -1 --cycle --height 60% < $sites`;
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
$site = "https://$site" unless $site =~ /\Ahttp/i;

say $site;
exec $^O eq 'darwin' ? 'open' : 'xdg-open', $site;
