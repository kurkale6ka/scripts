#! /usr/bin/env perl

# Wrapper for:
# openssl x509 -in <cert> -noout -subject -issuer -dates

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;

my $help = << 'MSG';
cert [options] certificate

--dates, -d
--issuer, -i
--subject, -s

many:
parallel --tag cert ::: *.crt
MSG

# Arguments
my ($dates, $issuer, $subject);
GetOptions (
   'd|dates' => \$dates,
   'i|issuer' => \$issuer,
   's|subject' => \$subject,
   'h|help' => sub {print $help; exit;}
) or die RED.'Error in command line arguments'.RESET, "\n";

$dates = '-dates' if $dates;
$issuer = '-issuer' if $issuer;
$subject = '-subject' if $subject;

@ARGV == 1 or die $help;
-f $ARGV[0] or die RED.$!.RESET, "\n";

unless ($dates or $issuer or $subject)
{
   exec qw/openssl x509 -in/, $ARGV[0], qw/-noout -subject -issuer -dates/;
} else {
   exec qw/openssl x509 -in/, $ARGV[0], '-noout', grep {defined}
   ($subject, $issuer, $dates);
}
