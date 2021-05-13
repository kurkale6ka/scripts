#! /usr/bin/env perl

# Canonical UNIX path
#
# https://perlweeklychallenge.org/blog/perl-weekly-challenge-112/#TASK1
# https://github.com/manwar/perlweeklychallenge-club/blob/master/challenge-112/kurkale6ka/perl/ch-1.pl
#
# one-liner versions:
# -E'$_=pop;s#/\.?(?=(/|$))##g;1while s#/([^/]+/)?\Q..##;say$_||"/"'
# -E'$_=pop;s#/\.?(?=(/|$))##g;{s#/([^/]+/)?\Q..##&&redo}say$_||"/"'
#
#  Input: "/a/"
# Output: "/a"
#
#  Input: "/a/b//c/"
# Output: "/a/b/c"
#
#  Input: "/a/b/c/../.."
# Output: "/a"

use v5.22;
use warnings;

$_ = shift;

# squeeze /s + remove final ones and get rid of /./
s#/\.?(?=(/|$))##gn;

# discard /dir/.. occurrences from path
1 while s#/([^/]+/)?\Q..##n;
# { redo if s#/([^/]+/)?\Q..##n }

say $_||'/'

__END__

Human readable version without regexes

# one-liner:
# -E'for(split/\//,pop){/^\.$/&&next;if(/^\.\.$/){pop@path}else{push@path,$_ if length}}say"/",join"/",@path'

my @path;

foreach (split m#/#, shift)
{
   next if $_ eq '.';

   if ($_ eq '..') {
      pop @path;
   } else {
      push @path, $_ if length;
   }
}

say '/', join '/', @path;
