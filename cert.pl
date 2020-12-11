#! /usr/bin/env perl

# Show Certificate/CSR info
# create CSR
#
# wrapper around:
# openssl x509, req, rsa

use strict;
use warnings;
use feature 'say';
use File::Basename 'fileparse';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use Term::ReadLine;

my $PINK = color('ansi205');
my $GRAY = color('ansi242');

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
   my $get = shift if $_[0] eq '-g';
   unless ($view)
   {
      unless ($check)
      {
         exec @_;
      } elsif ($get) {
         return `@_`;
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
   $check = 1;

   # Chain of Trust tests
   say $PINK.'Chain of Trust'.RESET;

   # continue if it looks like a certificate
   unless (($cert =~ /chain|\bca\b/i or $ext =~ /\.ch(ai)?n/in) and not $view)
   {
      my $intermediate = "$base.ca$ext";

      # ask for intermediate CAs
      unless (-f $intermediate)
      {
         warn "\n", RED.$base.BOLD.'.ca'.RESET.RED."$ext not found".RESET, "\n";

         my $term = Term::ReadLine->new('Intermediate certificates');
         $term->ornaments(0);
         $intermediate = $term->readline(YELLOW.'Intermediate CA certificates'.RESET.': ', $cert);
         chomp $intermediate;

         warn RED.'not found'.RESET, "\n" unless -f $intermediate;
      }

      # verify + show chain
      if (-f $intermediate or $view)
      {
         unless (-f $intermediate)
         {
            $intermediate ||= 'undef';
            $intermediate = RED.$intermediate.RESET;
         }

         # verify
         #
         # -CAfile <root CA certificate>:
         #  trusted (often root) CA certificate; usually not needed (except when self
         #  signing) as these trusted certificates will be in the OS/browser store
         #
         # -untrusted <intermediate CA certificates>
         run "openssl verify -untrusted $intermediate $cert";

         # show chain
         print "\n";

         sub chain($)
         {
            my $cert = shift;
            my $command = "openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -print_certs";
            unless ($view)
            {
               chomp ($_ = run '-g', $command);
               s/^.*cn=/$GRAY.$&.RESET/megi;
               say;
            } else {
               run $command;
            }
         }

         chain $cert;
         chain $intermediate unless $cert eq $intermediate;
      }
   }
   else {
      warn RED.'Certificate needed but got intermediate certificates (view with -v)'.RESET, "\n";
   }

   # Certificate/key match test
   say $PINK.'Certificate/key match test'.RESET;

   print CYAN.'Crt'.RESET.': ';
   run "openssl x509 -in $cert -noout -modulus | openssl md5";

   if (-f "$base.key")
   {
      print CYAN.'Key'.RESET.': ';
      run "openssl rsa -in $base.key -noout -modulus | openssl md5";
   }
   if (-f "$base.csr")
   {
      print CYAN.'CSR'.RESET.': ';
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
