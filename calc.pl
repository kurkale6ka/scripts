#! /usr/bin/env perl

# SIMPLE calculator

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
sub help()
{
   print << 'MSG';
Usage: calc math-expr

^ can be used for raising to a power (in addition to **)
÷ can be used in lieu of /
x can be used in lieu of *
* can be omitted in parenthesised expressions: a(b+c)

_ holds the result of the previous calculation

Tips:
- for arrows support, install Term::ReadLine::Gnu
- symlink this script to =
MSG
   exit;
}

# Arguments
GetOptions (
   'h|help' => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

my $prompt = CYAN.'>>'.RESET.' ';

my $res;
sub math_eval();

# read expression
if (@ARGV)
{
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
      # todo: add SIGINT (^C) handler to stay inside the loop
      exit if /^\h*(q(u(it?)?)?|e(x(it?)?)?)\h*$/in;
      if ($res = math_eval())
      {
         say $OUT $res;
      }
   }
   print "\n";
}

# intermediary calculation memory
my $ans;

sub math_eval()
{
   # validate input
   unless (m@^['"\h()_.\d%^x*÷/+-]*$@)
   {
      $_ = substr ($_, 0, 17) . '...' if length > 17;
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

   # allow pow with ^
   s/\^\^?/**/g;

   # allow x for multiplication
   tr/x/*/;

   # allow ÷ for division
   # todo: report that tr didn't work because of wide char ?
   s(÷)(/)g;

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
