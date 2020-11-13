#! /usr/bin/env perl

# Wrapper for:
# openssl x509 -in <cert> -noout ...
#
# default:
# openssl x509 -in <cert> -noout -subject -issuer -dates

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;

my $help = << 'MSG';
cert [options] certificate

--dates,       -d
--fingerprint, -f
--issuer,      -i
--modulus,     -m
--subject,     -s
--text,        -t
--verbose,     -v : print command without executing

many:
parallel --tag cert ::: *.crt
MSG

# Arguments
my ($dates, $fingerprint, $issuer, $modulus, $subject, $text, $verbose);
GetOptions (
   'd|dates'       => \$dates,
   'f|fingerprint' => \$fingerprint,
   'i|issuer'      => \$issuer,
   'm|modulus'     => \$modulus,
   's|subject'     => \$subject,
   't|text'        => \$text,
   'v|verbose'     => \$verbose,
   'h|help'        => sub {print $help; exit;}
) or die RED.'Error in command line arguments'.RESET, "\n";

$dates       = '-dates'       if $dates;
$fingerprint = '-fingerprint' if $fingerprint;
$issuer      = '-issuer'      if $issuer;
$modulus     = '-modulus'     if $modulus;
$subject     = '-subject'     if $subject;

@ARGV == 1 or die $help;
-f $ARGV[0] or die RED.$!.RESET, "\n";

sub run(@)
{
   unless ($verbose)
   {
      exec @_;
   } else {
      say "@_";
   }
}

unless ($dates or $fingerprint or $issuer or $modulus or $subject or $text)
{
   run qw/openssl x509 -in/, $ARGV[0], qw/-noout -subject -issuer -dates/;
} elsif (defined $text) {
   run qw/openssl x509 -in/, $ARGV[0], qw/-noout -text/;
} else {
   run qw/openssl x509 -in/, $ARGV[0], '-noout', grep {defined}
   ($subject, $issuer, $dates, $fingerprint, $modulus);
}
