#! /usr/bin/env perl

# Show Certificate/CSR info
# create CSR
#
# wrapper around:
# openssl x509, req, rsa

use strict;
use warnings;
use feature 'say';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use File::Basename 'fileparse';

my $help = << 'MSG';
Show Certificate/CSR info

cert [options] file

--check,       -c : cert/key match?
--csr,         -r : create CSR
--dates,       -d
--fingerprint, -f
--issuer,      -i
--subject,     -s
--text,        -t
--view,        -v : print openssl commands
MSG

# Arguments
my ($check, $csr, $dates, $fingerprint, $issuer, $subject, $text, $view);
GetOptions (
   'c|check'       => \$check,
   'r|csr'         => \$csr,
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

sub cert()
{
   # Certificate
   unless ($dates or $fingerprint or $issuer or $subject or $text)
   {
      # default fields
      run qw/openssl x509 -in/, $cert, qw/-noout -subject -issuer -dates/;
   } elsif (defined $text) {
      # whole cert
      run qw/openssl x509 -in/, $cert, qw/-noout -text/;
   } else {
      # custom fields
      run qw/openssl x509 -in/, $cert, '-noout', grep {defined}
      ($subject, $issuer, $dates, $fingerprint);
   }
}

# CSR
sub csr()
{
   unless ($csr)
   {
      # info
      run qw/openssl req -in/, $cert, qw/-noout -subject/;
   } else {
      # default
      my $subj = "/C=GB/ST=State/L=London/O=Company/OU=IT/CN=$name/emailAddress=@";

      # get existing
      if ($ext =~ /\.csr/i)
      {
         chomp ($_ = `openssl req -in $cert -noout -subject`);
         (undef, $subj) = split /=/, $_, 2;
      }

      # create
      run qw/openssl req -nodes -newkey rsa:2048 -keyout/, "$name.key", '-out', "$name.csr", '-subj', $subj;
   }
}

# Check whether cert/key match
sub check()
{
   my $crt = -f "$name.crt" ? 'crt' : 'pem';

   if (-f "$name.$crt")
   {
      print 'crt: ';
      run "openssl x509 -in $name.$crt -noout -modulus | openssl md5";
   }
   if (-f "$name.key")
   {
      print 'key: ';
      run "openssl rsa -in $name.key -noout -modulus | openssl md5";
   }
   if (-f "$name.csr")
   {
      print 'csr: ';
      run "openssl req -in $name.csr -noout -modulus | openssl md5";
   }
}

# Main
if ($check or $ext =~ /\.key/i) {
   $check = 1;
   check();
} elsif ($csr or $ext =~ /\.csr/i) {
   csr();
} else {
   cert();
}
