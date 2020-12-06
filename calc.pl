#! /usr/bin/env perl

# SIMPLE calculator

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

# Help
sub help()
{
   print << 'MSG';
Usage: calc math-expr

^ can be used for raising to a power (in addition to **)
x can be used in lieu of *
* can be omitted in parenthesised expressions: a(b+c)
exponent notation is supported

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
sub math_eval();
sub unicode();

GetOptions (
   'u|unicode' => \&unicode,
   'h|help'    => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Valid Math Symbols
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
[${fractions}\d][eE][-+]?\d+ # exponent notation
|
[${rparens})${fractions}\d]\h*[$superscripts]+ # raise to a power
|
['"\h${parens}()${fractions}\d_.%^x×✕✖*÷∕/➕+−-]
)*}xn;

my $res;
my $codeset = langinfo(CODESET); # utf8

# Arguments
if (@ARGV)
{
   @ARGV = map {decode $codeset, $_} @ARGV;
   $_ = "@ARGV";
   if ($res = math_eval())
   {
      say $res;
   }
}
else # STDIN
{
   my $term = Term::ReadLine->new('Simple calculator');
   $term->ornaments(0);
   my $OUT = $term->OUT || \*STDOUT;

   while (defined ($_ = $term->readline (CYAN.'>>'.RESET.' ')))
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

# Print recognized Unicode symbols
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

__DATA__

TODO: Tests

4e3, 4000, 'Exponent notation (1)'
7e-2, 0.07, 'Exponent notation (2)'
2^3, 8, 'Caret for raising to a power'
4x7, 28, 'ASCII x for multiplication'
17%3, 2, 'Modulo'
11✖8, 88, 'Unicode multiplication'
78÷3, 26, 'Unicode division'
50➕101, 151, 'Unicode addition'
231−17, 214, 'Unicode substraction'
3³, 27, 'Unicode superscript raise to a power'
⅗ / ⅚, 0.72, 'Unicode fractions'
⟮5+2⟯*（4-15）, -77, 'Unicode parens'
3(12-7), 15, 'Digit left parens implicit multiplication'
(4-9)7, -35, 'Right parens digit implicit multiplication'

All

179 / 12
15 * 5.2
12.3 - 14
8 + 88
-5e2 + 12
❨4÷7❩³
⅔e-34
3²/(2-19)(4+1.1) − 7(12-100) + 3^6
