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
my @extensions = qw/.bak .old .origin .backup .save/;

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

--all,    -a => include @extensions
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

# turn extensions into compiled patterns
@extensions = map {
   if (/^backup/ or /^save/)
   {
      qr/\..*$_/i; # .10_backup_2012 .rpmsave
   } else {
      qr/\.$_$/i;  # .bak, .old, ...
   }
} map {substr $_, 1} @extensions;

# Create a backup
if (@ARGV == 1)
{
   my $file = shift;
   exec qw/cp -i --/, $file, "$file.bak";
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

# Exclude CVS + cache folders
my @cvs = map qr/\.$_\b/, qw/git hg svn/;
my $cache = qr/\..*cache/i;

sub preprocess()
{
   my @inodes;
   foreach my $inode (@_)
   {
      next if any {$inode =~ /$_/} @cvs, $cache;
      push @inodes, $inode;
   }
   return @inodes;
}

# Backup files to delete, bar vim undo files, *.un~
my $del_pattern = qr/.+(?<!un)~$/;
my @deletes;

sub wanted()
{
   my $basename = $_;

   # skip non backup files
   return unless $basename =~ /$del_pattern/
      or any {$basename =~ /$_/} @extensions;

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

# Find backup files
find ({preprocess => \&preprocess, wanted => \&wanted}, '.');

# Delete in bulk
unlink @deletes if $delete;
