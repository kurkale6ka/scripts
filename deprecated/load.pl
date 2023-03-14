#! /usr/bin/env perl

use v5.22;
use warnings;
use re '/aa';
use Term::ANSIColor qw/color :constants/;

# CPU info
open my $FH, '<', '/proc/cpuinfo' or die RED.$!.RESET, "\n";

# load average
chomp (my @load = split ' ', `cat /proc/loadavg`);
my ($one, $five, $fifteen) = @load;

my $msg = 'increasing' if $one > $five or $one > $fifteen;

# get cores count
my $procs;
while (<$FH>) {
   chomp;
   ++$procs if /^processor\h*:\h*\d/;
}

map { $_ = ($procs > $_ ? GREEN : RED).$_.RESET } @load[0..2];

say '   1,    5,   15 : '.ITALIC.'minutes'.RESET;
say join (', ', @load[0..2]),
    ' : '.BOLD.$procs.RESET, ' cores ', ITALIC.'load average',
    ($msg ? " ($msg)" : '').RESET;
