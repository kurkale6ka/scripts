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

# use strict;
# use warnings;
use feature 'say';

# read expression
if (@ARGV)
{
   die "Usage: = math-expr\n" if $ARGV[0] =~ /-h|--help/i;
   $_ = "@ARGV";
} else {
   chomp ($_ = <STDIN>);
}

# validate input
unless (m@^[\s()'"_.\d%^x*÷/+-]*$@)
{
   s/\P{print}/?/g;
   die substr ($_, 0, 17), "...: bad symbols\n";
}

warn "% performs integer modulus only\n" if /%/;

# allow pow with ^
s/\^\^?/**/g;

# allow x for multiplication
tr/x/*/;

# allow ÷ for division
s(÷)(/)g;

# allow omitting * in parenthesised expressions
s/([\d)])\s*\(/$1*(/g if /[\d)]\s*\(/; # a(b+c), )(
s/\)\s*([\d])/)*$1/g if /\)\s*[\d]/;   # (b+c)a

die "Usage: = math-expr\n" unless $_;

say eval;
