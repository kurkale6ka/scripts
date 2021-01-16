#! /usr/bin/env perl

# Easier access to Perl help topics

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long qw/GetOptions :config no_ignore_case pass_through/;
use Config;
use Module::CoreList;
use File::Spec;
use List::Util 'uniq';

sub dirname(_)
{
   ( File::Spec->splitpath ($_[0]) )[1];
}

# Get Perl MANPATH
my @manpath = map
{
   $Config{substr $_, 0, 7}
}
Config::config_re qr/^man.dir/;

my $MANPATH = join ':', uniq map {dirname} @manpath;

# Get info: try man, then perldoc
sub info
{
   my $topic = shift;
   unless (system ("man -M $MANPATH $topic 2>/dev/null") == 0)
   {
      exec 'perldoc', $topic;
   }
   exit;
}

# Usage
sub help
{
   print << 'MSG';
Easier access to Perl help topics

mp            : perldoc
mp <function> : builtin function
mp v.         : variable $. (can also be invoked with \$.)
mp <section>  : (perl)re, (perl)run, ...
mp -s         : help sections
mp -m         : core module, -M can be used to view the code <= fzf needed

- extra options will be passed through to perldoc
- mp aka 'man Perl' is an alias to this script
MSG
   exit;
}

# Arguments
GetOptions (
   'module:s'        => \&module,
   'M|view-module:s' => \&module,
   'p|s|sections'    => sub {info 'perl'}, # help on Perl (which lists help sections)
   'help'            => \&help,
   '<>'              => \&extra
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

sub module
{
   my ($opt, $val) = @_;

   my $page;
   my $modules = Module::CoreList::find_version $];
   my @modules = keys %$modules;

   unless ($val)
   {
      chomp ($page = `printf '%s\n' @modules | fzf -0 -1 --cycle`);
   } else {
      chomp ($page = `printf '%s\n' @modules | fzf -q'$val' -0 -1 --cycle`);
   }

   exit unless $page;

   unless ($opt eq 'M')
   {
      info $page;
   } else {
      exec qw/perldoc -m/, $page;
   }
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
   my @pages;

   # Sections & misc
   foreach (@manpath)
   {
      opendir my $dh, $_ or die "$!\n";
      push @pages, grep {!/::/ and /$page/oi} readdir $dh;
   }

   if (@pages)
   {
      # -q isn't needed, it's supplied to enable highlighting
      if (chomp ($page = `printf '%s\n' @pages | fzf -q'$page' -0 -1 --cycle`))
      {
         my @parts = split /\./, $page; # topic.section(.gz)
         exec qw/man -M/, $MANPATH, @parts > 1 ? @parts[1,0] : @parts;
      }
   } else {
      exec 'perldoc', $page;
   }
}
