#! /usr/bin/env perl

# todo:
# perl -h
# man perl

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long qw/GetOptions :config pass_through/;
use Module::CoreList;

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
mp -m : core modules
mp --run,  -r
mp --var,  -v, v. ($.)
MSG
   exit;
}

# Arguments
GetOptions (
   'module' => \&module,
   'run'    => sub {info 'perlrun'}, # command line options
   'var'    => sub {info 'perlvar'}, # variables
   'help'   => \&help,
   '<>'     => \&extra,
) or die "Error in command line arguments\n";

sub extra
{
   if ($_[0] =~ /^-/)
   {
      exec 'perldoc', @_, @ARGV;
   } else {
      unshift @ARGV, @_;
      die("!FINISH");
   }
}

# todo: prefilter, view module with alt-v
sub module
{
   my $modules = Module::CoreList::find_version $];
   my @modules = keys %$modules;
   chomp (my $page = `printf '%s\n' @modules | fzf -0 -1 --cycle`);
   info $page;
   exit;
}

# checks
info 'perldoc' unless @ARGV;

my $page = shift;

# Variables
if ($page =~ /^[\$v].$/)
{
   $page =~ tr/v/$/;
   exec qw/perldoc -v/, $page;
}

# Default: builtin functions
exec qw/perldoc -f/, $page;
