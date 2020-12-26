#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use re '/aa';
use File::Find;
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;

# Help
sub help()
{
   print << 'MSG';
backup             : list backup~ files
backup --delete|-d : delete backup~ files

backup [-e ...] file : backup file to file.bak
backup --swap|-s file : swap backup file
MSG
   exit;
}

# Arguments
my $delete;
GetOptions (
   'd|delete' => \$delete,
   'h|help'   => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

if (@ARGV == 1)
{
   my $file = shift;
   say "cp $file $file.bak";
   exit;
} elsif (@ARGV > 1) {
   help();
}

# exclude vim undo files, ext: .un~
my $del_pattern = qr/.+(?<!un)~$/;
my @deletes;

find (\&wanted, '.');

# Wanted actions
sub wanted()
{
   return unless /$del_pattern/ or /\.bak$/i or /\.old$/i or /backup/i;

   my $name = $File::Find::name;

   # prepare $del_pattern files for deletion
   if ($delete)
   {
      push @deletes, $name if $name =~ /$del_pattern/;
      return;
   }

   # list
   say substr $name, 2 unless @ARGV;
}

unlink @deletes if $delete;
