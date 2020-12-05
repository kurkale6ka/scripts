#! /usr/bin/env perl

# SIMPLE calculator
# todo: tests!

use strict;
use warnings;
use feature 'say';
use utf8;
use Encode 'decode';
use open ':std', ':encoding(utf-8)';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use I18N::Langinfo qw/langinfo CODESET/;
use POSIX 'SIGINT';

# Catch SIGINT
POSIX::sigaction (SIGINT,
   POSIX::SigAction->new (sub { print YELLOW.'KeyboardInterrupt'.RESET; }));
$| = 1;

my $prompt = CYAN.'>>'.RESET.' ';

# todo: ok keys?
my %fractions = (
   '½' => 1/2,
   '⅓' => 1/3,
   '⅔' => 2/3,
   '¼' => 1/4,
   '¾' => 3/4,
   '⅕' => 1/5,
   '⅖' => 2/5,
   '⅗' => 3/5,
   '⅘' => 4/5,
   '⅙' => 1/6,
   '⅚' => 5/6,
   '⅐' => 1/7,
   '⅛' => 1/8,
   '⅜' => 3/8,
   '⅝' => 5/8,
   '⅞' => 7/8,
   '⅑' => 1/9,
   '⅒' => 1/10
);

my $fractions = join '', keys %fractions;
my $superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹';
my $lparens = '﴾⟮❪❨﹙（';
my $rparens = '﴿⟯❫❩﹚）';
my $parens = '﴾﴿⟮⟯❪❫❨❩﹙﹚（）';

my $symbols = qr{(
[\d${fractions}${rparens})]\h*[$superscripts]+
|
['"\h()${parens}_.${fractions}\d%^x×✕✖*÷∕/➕+−-]
)*}xn;

# Help
sub help()
{
   print << 'MSG';
Usage: calc math-expr

^ can be used for raising to a power (in addition to **)
x can be used in lieu of *
* can be omitted in parenthesised expressions: a(b+c)

_ holds the result of the previous calculation

Options:
--unicode, -u: print recognized Unicode Math symbols

Tips:
  for arrows support, install Term::ReadLine::Gnu
  symlink this script to =
MSG
   exit;
}

# Functions
sub unicode();
sub math_eval();

# Arguments
GetOptions (
   'u|unicode' => \&unicode,
   'h|help'    => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

my $res;
my $codeset = langinfo(CODESET); # utf8

# read expression
if (@ARGV)
{
   @ARGV = map {decode $codeset, $_} @ARGV;
   $_ = "@ARGV";
   if ($res = math_eval())
   {
      say $res;
   }
} else {
   my $term = Term::ReadLine->new('Simple calculator');
   $term->ornaments(0);
   my $OUT = $term->OUT || \*STDOUT;
   while (defined ($_ = $term->readline ($prompt)))
   {
      $_ = decode $codeset, $_;
      # todo: change SIGINT (^C) handler to stay inside the loop
      exit if /^\h*(q(u(it?)?)?|e(x(it?)?)?)\h*$/in;
      if ($res = math_eval())
      {
         say $OUT $res;
      }
   }
   print "\n";
}

# print recognized Unicode symbols

sub unicode()
{
   my @fractions = sort {$fractions{$a} <=> $fractions{$b}} keys %fractions;
   print <<CODES;
   operators: ×✕✖ ÷∕ ➕ −
   fractions: @fractions
superscripts: $superscripts, only if preceded by a number or a parenthesis
 parenthesis: $parens
CODES
   exit;
}


# global intermediary calculation memory
my $ans;

# Main
sub math_eval()
{
   # validate input
   if (/$symbols/ and $')
   {
      $_ = $';
      $_ = substr ($', 0, 17) . '...' if length > 17;
      s/\P{print}/?/g;
      $_ = RED."bad symbols: $_".RESET;
      die "$_\n" unless -t;
      warn "$_\n";
   }

   # replace _ with ans,
   # except when used as separator in big numbers such as 1_000_000
   if (/(?<!\d)_/)
   {
      if (defined $ans)
      {
         s/(?<!\d)_+/$ans/g;
      } else {
         return RED.'ans empty'.RESET;
      }
   }

   warn YELLOW.'% performs integer modulus only'.RESET, "\n" if /%/;

   # allow ^ for raising to a power
   s/\^\^?/**/g;

   # replace Unicode operator symbols with ASCII ones
   tr(x×✕✖÷∕➕−)(****//+-);

   # superscripts
   s/[$superscripts]+/**$&/g;
   tr/⁰¹²³⁴⁵⁶⁷⁸⁹/0123456789/;

   # fractions
   s/[$fractions]/$fractions{$&}/g;

   # fancy parenthesis
   s/[$lparens]/(/g;
   s/[$rparens]/)/g;

   # allow omitting * in parenthesised expressions
   s/([\d)])\h*\(/$1*(/g if /[\d)]\h*\(/; # a(b+c), )(
   s/\)\h*([\d])/)*$1/g if /\)\h*[\d]/;   # (b+c)a

   if (length)
   {
      # todo: exceptions handling
      if ($_ = eval)
      {
         return $ans = $_;
      }
   }

   # <enter> only
   return;
}
