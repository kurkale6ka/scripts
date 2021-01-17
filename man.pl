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
   ( File::Spec->splitpath($_[0]) )[1];
}

# Get man dirs plus associated pages extensions (man 3 Config)
# man1 => [man1dir, man1ext],
# man3 => [man3dir, man3ext],
my %man;
my $man_re = qr/(man\d)(dir|ext)/;

# config values (-Dman1dir=...) overwrite default values
foreach (Config::config_re($man_re), Config::config_re(qr/config_arg\d+/))
{
   next unless /$man_re/;
   my ($name, $type) = ($1, $2);
   unless (/config_arg\d+/)
   {
      $man{$name}->[$type eq 'dir'? 0 : 1] = $Config{$&};
   } else {
      $man{$name}->[$type eq 'dir'? 0 : 1] = (split /=/, $Config{$&})[1];
   }
}

my $MANPATH = join ':', uniq map {dirname @$_[0]} values %man;

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

mp            : locate help sections
mp <section>  : (perl)re, (perl)run, ...
mp <function> : builtin function
mp v.         : variable $. (can also be invoked with \$.)
mp -m         : core module, -M can be used to view the code <= fzf needed

- extra options will be passed through to perldoc (ex: -q for FAQ search)
- mp aka 'man Perl' is an alias to this script
MSG
   exit;
}

# Arguments
GetOptions (
   'module:s'        => \&module,
   'M|view-module:s' => \&module,
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
info 'perltoc' unless @ARGV;

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
   foreach (values %man)
   {
      my ($dir, $ext) = @$_;
      opendir my $dh, $dir or die "$!\n";
      push @pages, grep {!/::/ and /$page.*\.$ext/i} readdir $dh;
   }

   if (@pages)
   {
      # -q isn't needed, it's supplied to enable highlighting
      if (chomp ($_ = `printf '%s\n' @pages | fzf -q'$page' -0 -1 --cycle`))
      {
         my @parts = split /\./; # topic.section(.gz)
         exec qw/man -M/, $MANPATH, @parts > 1 ? @parts[1,0] : @parts;
      }
   } else {
      exec 'perldoc', $page;
   }
}
