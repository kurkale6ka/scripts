#! /usr/bin/env perl

# Show Certificate/CSR info
# create CSR
#
# wrapper around:
# openssl x509, req, rsa

use v5.22;
use warnings;
use File::Basename 'fileparse';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use List::Util qw/first uniq/;
use Term::ReadLine;

my $PINK = color 'ansi205';
my $GRAY = color 'ansi242';

my $help = << '----------';
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
----------

# Arguments
GetOptions (
   'c|check'       => \my $check,
   'r|csr'         => \my $csr,
   'd|dates'       => \my $dates,
   'f|fingerprint' => \my $fingerprint,
   'i|issuer'      => \my $issuer,
   's|subject'     => \my $subject,
   't|text'        => \my $text,
   'v|view'        => \my $view,
   'h|help'        => sub {print $help; exit;}
) or die RED.'Error in command line arguments'.RESET, "\n";

$dates       = '-dates'       if $dates;
$fingerprint = '-fingerprint' if $fingerprint;
$issuer      = '-issuer'      if $issuer;
$subject     = '-subject'     if $subject;

# Checks
die $help unless @ARGV == 1;
die RED.$!.RESET, "\n" unless -f $ARGV[0] or $csr;

my $cert = shift;
my @certificates = qw/.crt .pem/;

my ($base, $dirs, $ext) = fileparse($cert, qr/\.[^.]+$/);
$dirs = '' if $dirs eq './';

# use certificate.crt if given certificate.key for instance
sub change_cert()
{
   unless (grep /$ext/io, @certificates)
   {
      $ext = first {-f $dirs.$base.$_} @certificates;
      $cert = $dirs.$base.$ext;
   }
}

sub cert();
sub csr();
sub check();

# readline
my $term = Term::ReadLine->new ('certificates');
$term->ornaments (0);

# Main
if ($check) {
   change_cert();
   check();
} elsif ($csr) {
   $cert = "$base.csr";
   csr();
} elsif ($ext =~ /\.key/i) {
   change_cert();
   check();
} elsif ($ext =~ /\.csr/i) {
   csr();
} else {
   change_cert();
   cert();
}

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
      my $subj;

      # get subject from previous CSR
      if (-f $cert)
      {
         chomp ($_ = `openssl req -in $cert -noout -subject`);
         (undef, $subj) = split /=/, $_, 2;
      } else {
         # default
         my $fqdn = $base;
         $fqdn .= '.com' unless $fqdn =~ /\.com$/i;
         $subj = "/C=GB/ST=State/L=London/O=Company/OU=IT/CN=$fqdn/emailAddress=";

         unless (system 'perldoc -l Term::ReadLine::Gnu 1>/dev/null 2>&1')
         {
            $subj = $term->readline('Subject: ', $subj);
         } else {
            warn YELLOW.'Install Term::ReadLine::Gnu for better readline support'.RESET, "\n";
            say $subj;
            $subj = $term->readline('Subject: ');
         }
      }

      # create
      run qw/openssl req -nodes -newkey rsa:2048 -keyout/, "${dirs}${base}.key", '-out', $cert, '-subj', $subj;
   }
}

# Check 'chain of trust' + cert/key match
sub check()
{
   $check = 1;

   # Chain of Trust tests
   say $PINK.'Chain of Trust'.RESET;

   sub chain($)
   {
      my $cert = shift;
      my $command = "openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -print_certs";
      unless ($view)
      {
         chomp ($_ = run '-g', $command);
         s/^.*cn\h*=\h*/$GRAY.$&.RESET/megi;
         say;
      } else {
         run $command;
      }
   }

   # continue if it looks like a certificate
   unless (($base =~ /chain|\bca\b/i or $ext =~ /\.ch(ai)?n/in) and not $view)
   {
      my $intermediate = "${dirs}${base}.ca$ext";

      # ask for intermediate CAs
      unless (-f $intermediate)
      {
         warn "\n", RED.$base.BOLD.'.ca'.RESET.RED."$ext not found".RESET, "\n";

         $intermediate = $term->readline(YELLOW.'Intermediate CA certificates'.RESET.': ', $cert);

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
         print "\n" unless $view;

         chain $cert;
         chain $intermediate unless $cert eq $intermediate;
      }
   }
   else {
      chain $cert;
      die YELLOW.'Certificate needed but got intermediate certificates'.RESET, "\n";
   }

   # Certificate/key match test
   my %modulus = (
      crt => "openssl x509 -in $cert -noout -modulus | openssl md5",
      key => "openssl rsa -in ${dirs}$base.key -noout -modulus | openssl md5",
      csr => "openssl req -in ${dirs}$base.csr -noout -modulus | openssl md5",
   );

   foreach (keys %modulus)
   {
      if (-f "$base.$_")
      {
         $modulus{$_} = run '-g', $modulus{$_} unless $view;
      } else {
         delete $modulus{$_};
      }
   }

   my $err = '';
   unless ($view) {
      chomp %modulus;
      $err = ', modulus mismatch' unless scalar (uniq values %modulus) == 1;
   }

   # display
   say $PINK.'Certificate/key match test'.RESET;

   foreach (sort keys %modulus)
   {
      say CYAN.uc.RESET.": $modulus{$_}", $view ? '' : RED.$err.RESET;
   }
}
