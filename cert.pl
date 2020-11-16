#! /usr/bin/env perl

# Show Certificate/CSR info
#
# Wrapper for:
# openssl x509, req, rsa

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use File::Basename 'fileparse';

my $help = << 'MSG';
cert [options] file

--check,       -c : cert/key match?
--dates,       -d
--fingerprint, -f
--issuer,      -i
--subject,     -s
--text,        -t
--view,        -v : print command without executing

many:
parallel --tag cert ::: *.crt
MSG

# Arguments
my ($check, $dates, $fingerprint, $issuer, $subject, $text, $view);
GetOptions (
   'c|check'       => \$check,
   'd|dates'       => \$dates,
   'f|fingerprint' => \$fingerprint,
   'i|issuer'      => \$issuer,
   's|subject'     => \$subject,
   't|text'        => \$text,
   'v|view'        => \$view,
   'h|help'        => sub {print $help; exit;}
) or die RED.'Error in command line arguments'.RESET, "\n";

$dates       = '-dates'       if $dates;
$fingerprint = '-fingerprint' if $fingerprint;
$issuer      = '-issuer'      if $issuer;
$subject     = '-subject'     if $subject;

# Checks
@ARGV == 1 or die $help;
-f $ARGV[0] or die RED.$!.RESET, "\n";

my $cert = shift;
my ($name, undef, $ext) = fileparse($cert, qr/\.[^.]*/);

$check = 1 if $ext =~ /\.key/;

# scratch wrong args for a CSR
if ($ext =~ /\.csr/)
{
   undef $_ foreach $dates, $fingerprint, $issuer, $text;
}

# execute or print external commands
sub run(@)
{
   unless ($view)
   {
      unless ($check)
      {
         exec @_;
      } else {
         system @_;
      }
   } else {
      say "@_";
      exit unless $check;
   }
}

# check whether private/public key match
if ($check)
{
   my $crt = -f "$name.crt" ? 'crt' : 'pem';

   print 'crt: ';
   run "openssl x509 -in $name.$crt -noout -modulus | openssl md5";

   print 'key: ';
   run "openssl rsa -in $name.key -noout -modulus | openssl md5";

   if (-f "$name.csr")
   {
      print 'csr: ';
      run "openssl req -in $name.csr -noout -modulus | openssl md5";
   }

   exit;
}

# default output
unless ($dates or $fingerprint or $issuer or $subject or $text)
{
   if ($ext =~ /\.csr/)
   {
      run qw/openssl req -in/, $cert, qw/-noout -subject/;
   } else {
      run qw/openssl x509 -in/, $cert, qw/-noout -subject -issuer -dates/;
   }
}

# custom output
if (defined $text) {
   run qw/openssl x509 -in/, $cert, qw/-noout -text/;
} else {
   run qw/openssl x509 -in/, $cert, '-noout', grep {defined}
   ($subject, $issuer, $dates, $fingerprint);
}
