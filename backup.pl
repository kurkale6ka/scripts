#! /usr/bin/env perl

# Backups: create, cleanup, manage

use strict;
use warnings;
use feature 'say';
use re '/aa';
use File::Find;
use Getopt::Long qw/GetOptions :config bundling/;
use List::Util 'any';
use Term::ANSIColor qw/color :constants/;

my $BLUE = color('ansi69');
my $GRAY = color('ansi242');

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

backup    :   list [-a] backup~ files
backup -d : delete [-a] backup~ files

backup    file         : create file.bak
backup -s [file[.bak]] : swap backup with original, file <~> file.bak

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
   's|swap:s' => \$swap,
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
   # todo + infer name if only one present
   my $file = shift;
   say "Swapped $file";
   exit;
}

swap $swap if $swap and -f $swap;

# Backup files to delete, bar vim undo files, *.un~
my $del_pattern = qr/.+(?<!un)~$/;
my @deletes;

my @cvs = map qr/\.$_/, qw/git hg svn/;
my $cache = qr/\..*cache/i;

# Find backup files
find ({wanted => \&wanted, preprocess => \&preprocess}, '.');

# exclude CVS + cache folders
sub preprocess
{
   my @inodes;
   foreach my $inode (@_)
   {
      next if any {$inode =~ /$_/} @cvs, $cache;
      push @inodes, $inode;
   }
   return @inodes;
}

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
   if ($name =~ /$del_pattern/ or $all)
   {
      # ./ stripped, blue dirs / gray backup~
      $name =~ s/..(.*)($basename)/$BLUE.$1.$GRAY.$2.RESET/e;
      say $name;
   }
}

# Delete in bulk
unlink @deletes if $delete;
