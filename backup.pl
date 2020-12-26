#! /usr/bin/env perl

# Backups: create, cleanup, manage

use strict;
use warnings;
use feature 'say';
use re '/aa';
use File::Find;
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;
use List::Util 'any';

# extra backup extensions, in addition to ~
my @extensions = qw/bak old/;
my @includes = map {".$_"} @extensions;

@extensions = map {qr/\.$_$/i} @extensions;

# Help
sub help()
{
   $" = ', ';
   print <<MSG;
SYNOPSIS

backup    :   list (-a) backup~ files
backup -d : delete (-a) backup~ files

backup    file       : create file.bak
backup -s file(.bak) : swap backup with original, file <~> file.bak

OPTIONS

--all,    -a => include @includes + any match of 'backup'
--delete, -d
--swap,   -s
MSG
   exit;
}

# Arguments
my ($all, $delete, $swap);
GetOptions (
   'a|all'    => \$all,
   'd|delete' => \$delete,
   's|swap=s' => \$swap,
   'h|help'   => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Create a backup
if (@ARGV == 1)
{
   # todo: fix --
   my $file = shift;
   exec qw/cp -i/, $file, "$file.bak";
}
elsif (@ARGV > 1)
{
   help();
}

# Swap backup file with original
sub swap($)
{
   # todo
   my $file = shift;
   say "Swapped $file";
   exit;
}

swap $swap if $swap and -f $swap;

# Backup files to delete, bar vim undo files, *.un~
my $del_pattern = qr/.+(?<!un)~$/;
my @deletes;

# Find backup files
find (\&wanted, '.');

# actions
sub wanted()
{
   my $basename = $_;

   return unless $basename =~ /$del_pattern/
      or any {$basename =~ /$_/} @extensions
      or /backup/i;

   my $name = $File::Find::name;

   # collect files for deletion
   if ($delete)
   {
      push @deletes, $name if $name =~ /$del_pattern/ or $all;
      return;
   }

   # List
   say substr $name, 2 if $name =~ /$del_pattern/ or $all;
}

# Delete in bulk
unlink @deletes if $delete;
