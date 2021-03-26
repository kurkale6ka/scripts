#! /usr/bin/env perl

# SIMPLE calculator

use v5.26;
use warnings;
use utf8;
use open qw/:std :encoding(UTF-8)/;
use Encode 'decode';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long 'GetOptions';
use POSIX 'SIGINT';

my $B = color 'bold';
my $R = color 'reset';

# Catch SIGINT
POSIX::sigaction (SIGINT, POSIX::SigAction->new (sub {
   print YELLOW.'KeyboardInterrupt'.RESET;
}));

$| = 1;

# Help
my $help = << "------";
Usage: calc math-expr

x can be used in lieu of *
* can be omitted in parenthesised expressions: a(b+c)
^ can be used for raising to a power (in addition to **)

_ holds the result of the previous calculation

Options:
--tests,   -t : run unit tests
--unicode, -u : print supported Unicode symbols (no -- in interactive mode)

Tips:
• exponent notation (m${B}e${R}n ⇔ m×10ⁿ) is supported
• for arrows support, install Term::ReadLine::Gnu
• symlink this script to =
------

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

my $numbers = '𝟎𝟢𝟬𝟶𝟏𝟣𝟭𝟷𝟐𝟤𝟮𝟸𝟑𝟥𝟯𝟹𝟒𝟦𝟰𝟺𝟓𝟧𝟱𝟻𝟔𝟨𝟲𝟼𝟕𝟩𝟳𝟽𝟖𝟪𝟴𝟾𝟗𝟫𝟵𝟿';
my $fractions = join '', keys %fractions;
my $superscripts = '⁰¹²³⁴⁵⁶⁷⁸⁹';
my $lparens = '﴾⟮❪❨﹙（';
my $rparens = '﴿⟯❫❩﹚）';
my $parens = '﴾﴿⟮⟯❪❫❨❩﹙﹚（）';

my $symbols = qr{(
[${numbers}${fractions}\d][eE][-+]?\d+ # exponent notation
|
[${rparens})${numbers}${fractions}\d]\h*[$superscripts]+ # raise to a power
|
['"\h${parens}()${numbers}${fractions}\d⅟_.%^x×✕✖*÷∕⁄/➕+−-]
)*}xn;

# Global variables
my $res;
my $ans; # memory

# Options
GetOptions (
   'tests'   => \my $tests,
   'unicode' => sub { unicode();   exit },
   'help'    => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

if ($tests) { tests(); exit }

# Arguments
if (@ARGV)
{
   @ARGV = map {decode 'UTF-8', $_, Encode::FB_CROAK | Encode::LEAVE_SRC} @ARGV;
   $_ = join '', @ARGV;
   exit unless length;
   say $res if defined ($res = math_eval());
}
else # STDIN
{
   my $term = Term::ReadLine->new ('Simple calculator');
   $term->ornaments (0);
   my $OUT = $term->OUT || \*STDOUT;

   while (defined ($_ = $term->readline (CYAN.'>>'.RESET.' ')))
   {
      next unless length;
      $_ = decode 'UTF-8', $_, Encode::FB_CROAK | Encode::LEAVE_SRC;

      exit if /^\h*(q(uit)?|e(xit)?)\h*$/in;

      if (/^\h*(h(elp)?|\?+)\h*$/in) { print $help; next }
      if (/^\h*u(nicode)?\h*$/in)    { unicode();   next }

      say $OUT $res if defined ($res = math_eval());
   }
}

# Main
sub math_eval
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
      return undef;
   }

   # replace _ with ans,
   # except when used as separator in big numbers such as 1_000_000
   if (/(?<!\d)_/)
   {
      if (defined $ans)
      {
         s/(?<!\d)_+/$ans/g;
      } else {
         warn RED.'ans empty'.RESET, "\n";
         return undef;
      }
   }

   if (/%/)
   {
      warn YELLOW.'% performs integer modulus only'.RESET, "\n" unless $tests;
   }

   # replace & squeeze Unicode operator symbols with ASCII ones
   tr(x×✕✖÷∕⁄➕−)(****///+-)s;

   # squeeze
   tr(-+/%)()s;
   s/\*{3,}/**/;

   # allow ^ for raising to a power
   s/\^+/**/g;

   # numbers
   tr/𝟎𝟢𝟬𝟶𝟏𝟣𝟭𝟷𝟐𝟤𝟮𝟸𝟑𝟥𝟯𝟹𝟒𝟦𝟰𝟺𝟓𝟧𝟱𝟻𝟔𝟨𝟲𝟼𝟕𝟩𝟳𝟽𝟖𝟪𝟴𝟾𝟗𝟫𝟵𝟿/0000111122223333444455556666777788889999/;

   # superscripts
   s/[$superscripts]+/**$&/g;
   tr/⁰¹²³⁴⁵⁶⁷⁸⁹/0123456789/;

   # fancy parenthesis
   s/[$lparens]/(/g;
   s/[$rparens]/)/g;

   # allow omitting * in parenthesised expressions
   s/ ( [\d$fractions)] ) \h* \( /$1*(/gx; # a(b+c), )(
   s/ \) \h* ( [\d$fractions] )  /)*$1/gx; # (b+c)a

   s/([$fractions])\h*(\d)/$1*$2/g;
   s/(\d)\h*([$fractions])/$1*$2/g;
   s/([$fractions])\h*([$fractions])/$1*$2/g;

   # fractions
   s/[$fractions]/$fractions{$&}/g;
   s(⅟)(1/)g;

   # todo: exceptions handling
   if (defined ($_ = eval))
   {
      return $ans = $_;
   } else {
      return undef;
   }
}

# Print recognized Unicode symbols
sub unicode
{
   my @fractions = sort {$fractions{$a} <=> $fractions{$b}} keys %fractions;
   print <<~ "CODES";
      operators: ×✕✖ ÷∕⁄ ➕ −
        numbers: $numbers
      fractions: @fractions ⅟
   superscripts: (number)$superscripts
    parenthesis: $parens
   CODES
}

sub tests
{
   my $res;
   while (<DATA>)
   {
      next if /^#/ or /^$/;
      chomp;
      my ($title, $expr, $ans) = split /\h*\|\h*/;
      $_ = $expr;
      $res = math_eval();
      my $cl = ($res == $ans) ? GREEN : RED;
      my $rs = RESET;
      printf "$cl%-32s$rs │ %s = %s ? $cl%s$rs\n", $title, $expr, $ans, $res;
   }
}

__DATA__

# Tests

Multiplication                   | 12_345_679 * 8                     | 98765432
Multiplication ASCII x           | 12_345_679 x 9                     | 111111111
Multiplication parens (          | 3(12-7)                            | 15
Multiplication parens )          | (4-9)7                             | -35
Multiplication Unicode           | 11 ✖ 8                             | 88
Multiplication Unicode fractions | ⅒⅗                                 | 0.06
Power ^                          | 2^3                                | 8
Power superscript Unicode        | 3³                                 | 27
Division                         | 179 / 16                           | 11.1875
Division Unicode                 | 78 ÷ 3                             | 26
Division fractions Unicode 1.    | ¼ / ⅒                              | 2.5
Division fractions Unicode 2.    | ⅟4                                 | 0.25
Addition                         | 8 + 88                             | 96
Addition Unicode                 | 50 ➕ 101                          | 151
Substraction                     | 19 - 277                           | -258
Substraction Unicode             | 231 − 17                           | 214
Exponent notation e+             | 4e3                                | 4000
Exponent notation e-             | 7e-2                               | 0.07
Modulo                           | 17 % 3                             | 2
Parens Unicode                   | ⟮5+2⟯*（4-15）                     | -77
Numbers Unicode                  | 𝟭𝟥 + 𝟨𝟿                            | 82
Squeeze                          | 3 --- 4                            | -1
Squeeze power                    | 3 ***************** 3              | 27
Combined 1.                      | -5e2 + 12                          | -488
Combined 2.                      | ❨4÷8❩⁷                             | 0.0078125
Combined 3.                      | ⅕e-12                              | 2e-13
Combined 4.                      | 3²/(2-19)(4+1.1) − 7(12-100) + 3^6 | 1342.3
Combined 5.                      | ⅒(3-5)                             | -0.2
Memory _ set                     | 17 - 39                            | -22
Memory _ get                     | _^2                                | -484
