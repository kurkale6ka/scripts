#! /usr/bin/env perl

# SIMPLE calculator
#
# Usage: = math-expr
#
# Notes:
#   symlink this script to =
#   ^ can be used for powers (in addition to **)
#   ÷ can be used in lieu of /
#   x can be used in lieu of *
#   * can be omitted in parenthesised expressions: a(b+c)

use strict;
use warnings;
use re '/aa';
use feature 'say';

my $ans;
sub math_eval();

# read expression
if (@ARGV)
{
   die "= math-expr, ans stored in _\n" if $ARGV[0] =~ /-h|--help/i;
   $_ = "@ARGV";
   print math_eval();
} else {
   while (1)
   {
      print '>> ';
      defined ($_ = <STDIN>) or die "\n";
      chomp;
      exit if /^(q(uit)?|e(xit)?)$/in;
      print math_eval();
   }
}

sub math_eval()
{
   # validate input
   unless (m@^[\h()'"_.\d%^x*÷/+-]*$@)
   {
      s/\P{print}/?/g;
      die substr ($_, 0, 17), "...: bad symbols\n";
   }

   # replace _ with the result of the previous calculation
   # except when used as separator in big numbers such as 1_000_000
   if (/(?<!\d)_/)
   {
      if (defined $ans)
      {
         s/(?<!\d)_+/$ans/g;
      } else {
         return "ans empty\n";
      }
   }

   warn "% performs integer modulus only\n" if /%/;

   # allow pow with ^
   s/\^\^?/**/g;

   # allow x for multiplication
   tr/x/*/;

   # allow ÷ for division
   s(÷)(/)g;

   # allow omitting * in parenthesised expressions
   s/([\d)])\h*\(/$1*(/g if /[\d)]\h*\(/; # a(b+c), )(
   s/\)\h*([\d])/)*$1/g if /\)\h*[\d]/;   # (b+c)a

   if (length)
   {
      # todo: exceptions handling + readline support
      if ($_ = eval)
      {
         $ans = $_;
         return "$ans\n";
      }
   }

   # <enter> only
   return;
}
