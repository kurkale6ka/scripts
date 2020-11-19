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

--check,       -c : chain of trust + cert/key match
--csr,         -r : create CSR
--dates,       -d
--fingerprint, -f
--issuer,      -i
--subject,     -s
--text,        -t
--view,        -v : print openssl commands

Intermediate certificates can be appended to:
* the certificate itself
* the certificate and put in a separate chain file

SSL Certificate Checker
https://www.digicert.com/help/
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
my ($base, undef, $ext) = fileparse($cert, qr/\.[^.]*/);

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
      my $subj = "/C=GB/ST=State/L=London/O=Company/OU=IT/CN=$base/emailAddress=@";

      # get existing
      if (-f "$base.csr")
      {
         chomp ($_ = `openssl req -in $base.csr -noout -subject`);
         (undef, $subj) = split /=/, $_, 2;
      }

      # create
      run qw/openssl req -nodes -newkey rsa:2048 -keyout/, "$base.key", '-out', "$base.csr", '-subj', $subj;
   }
}

# Check 'chain of trust' + cert/key match
sub check()
{
   if ($cert =~ /chain|\bca\b/i or $ext =~ /\.ch(ai)?n/in)
   {
      die RED.'Certificate needed but got intermediate certificates'.RESET, "\n";
   }

   $check = 1;

   my $crt = -f "$base.crt" ? 'crt' : 'pem';

   sub ask($$)
   {
      my ($test, $message) = @_;
      my $file;

      if (-f $test)
      {
         $file = $test;
      } else {
         warn "\n", RED."$test not found".RESET, "\n";
         print "$message: ";
         chomp ($file = <STDIN>);
         die RED.'not found'.RESET, "\n" unless -f $file;
      }

      return $file;
   }

   # -CAfile <root CA certificate>:
   #  trusted (often root) CA certificate; usually not needed (except when self
   #  signing) as these trusted certificates will be in the OS/browser store
   #
   # -untrusted <intermediate CA certificate>

   my $PINK = color('ansi205');

   # Chain of Trust test
   say $PINK.'Chain of Trust'.RESET;

   my $intermediate = ask "$base.ca.$crt", 'Intermediate CA certificate';

   # verify
   if (-f "$base.$crt")
   {
      run "openssl verify -untrusted $intermediate $base.$crt";
   } else {
      die RED."$base.$crt certificate not found".RESET, "\n";
   }

   my $chain = ask "$base.chn", 'Full chain';

   # show chain
   print "\n";
   run "openssl crl2pkcs7 -nocrl -certfile $chain | openssl pkcs7 -noout -print_certs";

   # Certificate/key match test
   say $PINK.'Certificate/key match test'.RESET;

   if (-f "$base.$crt")
   {
      print CYAN.'crt'.RESET.': ';
      run "openssl x509 -in $base.$crt -noout -modulus | openssl md5";
   }
   if (-f "$base.key")
   {
      print CYAN.'key'.RESET.': ';
      run "openssl rsa -in $base.key -noout -modulus | openssl md5";
   }
   if (-f "$base.csr")
   {
      print CYAN.'csr'.RESET.': ';
      run "openssl req -in $base.csr -noout -modulus | openssl md5";
   }
}

# Main
if ($check) {
   check();
} elsif ($csr) {
   csr();
} elsif ($ext =~ /\.key/i) {
   check();
} elsif ($ext =~ /\.csr/i) {
   csr();
} else {
   cert();
}
