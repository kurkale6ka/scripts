#! /usr/bin/env perl

# Show Certificate/CSR info
# create CSR
#
# wrapper around:
# openssl x509, req, rsa, ...

use v5.22;
use warnings;
use File::Basename 'fileparse';
use File::Temp 'tempfile';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use List::Util qw/first uniq/;
use Term::ReadLine;

my $PINK = color 'ansi205';
my $GRAY = color 'ansi242';

my $help = << '----------';
Show Certificate/CSR info

cert [options] file|URL

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

my $url;

# Checks
die $help unless @ARGV == 1;

my $cert = shift;
$cert =~ m#(.+://)?\K[^/]+#; # strip protocol://
$cert = $&;

sub run(@);
my @certificates = qw/.crt .pem/;

unless (-f $cert)
{
   $url = 1;
   my $cert_from_url = run '-g', "openssl s_client -showcerts -connect $cert:443 </dev/null 2>/dev/null";
   $cert_from_url or die RED.'URL issue'.RESET, "\n";
   $cert = File::Temp->new (SUFFIX => '.crt');
   say $cert $cert_from_url;
}

my ($base, $dirs, $ext) = fileparse($cert, qr/\.[^.]+$/);
$dirs = '' if $dirs eq './';

# use certificate.crt if given certificate.key for instance
sub change_cert
{
   return if grep /$ext/io, @certificates;
   if (my $ext = first {-f $dirs.$base.$_} @certificates)
   {
      $cert = $dirs.$base.$ext;
   }
}

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
   if ($view) {
      say "@_";
      exit unless $check or $url;
   } elsif ($get) {
      chomp (my $output = `@_`);
      return $output;
   } elsif ($check) {
      system @_;
   } else {
      exec @_;
   }
}

sub cert
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
sub csr
{
   unless ($csr)
   {
      # info
      run qw/openssl req -in/, $cert, qw/-noout -subject/;
   } else {
      my $fqdn = $base;
      $fqdn .= '.com' unless $fqdn =~ /\.com$/i;

      # default subject
      my $prompt = 'Subject: ';
      my $subj = "/C=GB/ST=State/L=London/O=Company/OU=IT/CN=$fqdn/emailAddress=";
      my $subj_fields = ' ' x length($prompt) . $GRAY.$subj.RESET;

      # get subject from previous CSR
      if (-f $cert)
      {
         say $subj_fields unless $view;
         chomp ($_ = `openssl req -in $cert -noout -subject`);
         (undef, $subj) = split /=/, $_, 2;
      }

      unless ($view)
      {
         if (system ('perldoc -l Term::ReadLine::Gnu 1>/dev/null 2>&1') == 0)
         {
            $subj = $term->readline($prompt, $subj);
         } else {
            warn YELLOW.'Install Term::ReadLine::Gnu for better readline support'.RESET, "\n";
            say $subj_fields;
            $subj = $term->readline($prompt);
         }
      }

      # create
      run qw/openssl req -nodes -newkey rsa:2048 -keyout/, $dirs."$base.key", '-out', $cert, '-subj', $subj;
   }
}

# Check 'chain of trust' + cert/key match
sub check
{
   $check = 1;

   # Chain of Trust tests
   say $PINK.'Chain of Trust'.RESET;

   sub chain
   {
      my $cert = shift;
      my $command = "openssl crl2pkcs7 -nocrl -certfile $cert | openssl pkcs7 -noout -print_certs";
      unless ($view)
      {
         $_ = run '-g', $command;
         s/\n{2,}(?=issuer|\z)/\n/gi;
         s/\n{2,}/\n\n/g;
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
      unless ($url or -f $intermediate)
      {
         warn "\n", RED.$base.BOLD.'.ca'.RESET.RED."$ext not found".RESET, "\n";

         $intermediate = $term->readline(YELLOW.'Intermediate CA certificates'.RESET.': ', $cert);
         $intermediate =~ s/\h+\z//;

         warn RED.'not found'.RESET, "\n" unless -f $intermediate;
      }

      # verify + show chain
      if ($url or -f $intermediate or $view)
      {
         unless (-f $intermediate)
         {
            $intermediate ||= 'undef';
            $intermediate = RED.$intermediate.RESET;
         }

         $intermediate = $cert if $url;

         # verify
         #
         # -CAfile <root CA certificate>:
         #  trusted (often root) CA certificate; usually not needed (except when self
         #  signing) as these trusted certificates will be in the OS/browser store
         #
         # -untrusted <intermediate CA certificates>
         #
         # `` (-g) to discard output but still set $?
         run '-g', qw/openssl verify -untrusted/, $intermediate, $cert;
         say 'verify certificate chains: ', $?==0 ? 'ok' : RED.'fail'.RESET unless $view;

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
      key => "openssl rsa  -in ${dirs}$base.key -noout -modulus | openssl md5",
      csr => "openssl req  -in ${dirs}$base.csr -noout -modulus | openssl md5",
   );

   foreach (keys %modulus)
   {
      if ($_ eq 'crt' or -f "$base.$_")
      {
         $modulus{$_} = run '-g', $modulus{$_} unless $view;
      } else {
         delete $modulus{$_};
      }
   }

   my $err = '';
   unless ($view) {
      $err = ', modulus mismatch' unless scalar (uniq values %modulus) == 1;
   }

   # display
   say $PINK.'Modulus match test'.RESET;

   foreach (sort keys %modulus)
   {
      say CYAN.uc.RESET.": $modulus{$_}", $view ? '' : RED.$err.RESET;
   }
}
