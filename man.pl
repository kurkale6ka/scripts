#! /usr/bin/env perl

# Easier access to Perl help topics

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
   unless (system ("man $topic 2>/dev/null") == 0)
   {
      unless (system ("man perl$topic 2>/dev/null") == 0)
      {
         exec 'perldoc', $topic;
      }
   }
   exit;
}

# Usage
sub help
{
   print << 'MSG';
mp            : perldoc
mp <function> : builtin function
mp v.         : variable $. (can also be invoked with \$.)
mp <section>  : (perl)re, (perl)run, ...
mp -s         : help sections
mp -m         : core modules

Extra options will be passed through to perldoc
MSG
   exit;
}

# Arguments
GetOptions (
   'module'       => \&module,
   'p|s|sections' => sub {info 'perl'}, # help on Perl (which lists help sections)
   'help'         => \&help,
   '<>'           => \&extra
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
   info $page if $page;
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

# Builtin functions
unless (system ("perldoc -f $page 2>/dev/null") == 0)
{
   # Sections & misc
   info $page;
}
