#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long;

# Help: man, perldoc
sub info
{
   my $topic = shift;
   unless (system ('man', $topic) == 0)
   {
      exec 'perldoc', $topic;
   }
   exit;
}

# Usage
sub help
{
   print << 'MSG';
mp
mp split
mp --op,   -o
mp --run,  -r
mp --regex
mp --var,  -v, v. ($.)
MSG
   exit;
}

# Arguments
GetOptions (
   'op'    => sub {info 'perlop'},  # operators
   'r|run' => sub {info 'perlrun'}, # command line options
   'regex' => sub {info 'perlre'},  # regex
   'var'   => sub {info 'perlvar'}, # variables
   'help'  => \&help
) or die "Error in command line arguments\n";

# checks
info 'perl' unless @ARGV;

my $page = shift;

# Variables
if ($page =~ /^[\$v].$/)
{
   $page =~ tr/v/$/;
   exec qw/perldoc -v/, $page;
}

# Default: builtin functions
exec qw/perldoc -f/, $page;
