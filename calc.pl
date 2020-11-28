#! /usr/bin/env perl

# SIMPLE calculator

use strict;
use warnings;
use re '/aa';
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
sub help()
{
   print << 'MSG';
Usage: = math-expr

^ can be used for powers (in addition to **)
÷ can be used in lieu of /
x can be used in lieu of *
* can be omitted in parenthesised expressions: a(b+c), (b+c)a

replace _ with the result of the previous calculation
except when used as separator in big numbers such as 1_000_000

symlink this script to =
MSG
   exit;
}

# Arguments
GetOptions (
   'h|help' => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

my $ans;
sub math_eval();

# read expression
if (@ARGV)
{
   $_ = "@ARGV";
   print math_eval();
} else {
   while (1)
   {
      print CYAN.'>>'.RESET.' ';
      defined ($_ = <STDIN>) or die "\n";
      chomp;
      exit if /^\h*(q(u(it?)?)?|e(x(it?)?)?)\h*$/in;
      print math_eval();
   }
}

sub math_eval()
{
   # validate input
   unless (m@^['"#\h()_.\d%^x*÷/+-]*$@)
   {
      $_ = substr ($_, 0, 17) . '...' if length > 17;
      s/\P{print}/?/g;
      die RED."bad symbols: $_".RESET, "\n";
   }

   my $comment = '';

   # replace _ with ans
   if (/(?<!\d)_/)
   {
      if (defined $ans)
      {
         $comment = ' '.GREEN."# _ was $ans".RESET unless /^_+$/;
         s/(?<!\d)_+/$ans/g;
      } else {
         return RED.'ans empty'.RESET, "\n";
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
      # todo: exceptions handling + readline support
      if ($_ = eval)
      {
         $ans = $_;
         return "${ans}${comment}\n";
      }
   }

   # <enter> only
   return;
}
