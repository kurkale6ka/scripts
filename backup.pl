#! /usr/bin/env perl

# Backups: create, cleanup, manage

use v5.12;
use warnings;
use re '/aa';
use File::Find;
use Getopt::Long qw/GetOptions :config bundling/;
use List::Util qw/any none/;
use Term::ANSIColor qw/color :constants/;
use File::Basename 'fileparse';

my $BLUE = color 'ansi69';
my $GRAY = color 'ansi242';

# extra backup extensions, in addition to ~
my @extensions = qw/.bak .old .origin .backup .save/;

# Help
sub help()
{
   $" = ', ';
   print <<MSG;
backup    :   list [-a] backups~
backup -d : delete [-a] backups~

backup    file      : create file.bak
backup -s [pattern] : swap backup with original

Options
--all,    -a => include @extensions
--delete, -d
--swap,   -s
MSG
   exit;
}

# Arguments
GetOptions (
   'a|all'    => \my $all,
   'd|delete' => \my $delete,
   's|swap:s' => \my $swap,
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
sub swap()
{
   my @ext = qw/bak new/;
   my @ext_rg = map qr/\.$_$/i, @ext;

   # not a file or one without extension
   if (not -f $swap or $swap !~ /\./)
   {
      opendir my $DH, '.' or die RED.$!.RESET, "\n";

      my
      @backups = grep { /$ext_rg[0]/ or /$ext_rg[1]/ } readdir $DH;
      @backups = grep { /$swap/ } @backups if $swap;

      if (@backups)
      {
         if (@backups > 1)
         {
            die RED.'Found multiple backups. Please select one with -s'.RESET, "\n"
         }
         $swap = shift @backups;
      } else {
         die RED.'No backups found'.RESET, "\n";
      }
   }
   elsif (none {$swap =~ /$_/} @ext_rg)
   {
      die RED.'Wrong extension'.RESET, "\n";
   }

   my ($name, undef, $ext) = fileparse($swap, qr/\.[^.]+$/);

   $ext = $ext =~ /$ext_rg[1]/ ? ".$ext[0]" : ".$ext[1]";

   if (system (qw/mv -i --/, $name, $name.$ext) == 0)
   {
      if (system (qw/mv -i --/, $swap, $name) == 0)
      {
         say "$swap -> $name $GRAY-> ${name}${ext}".RESET;
      }
   }
}

if (defined $swap)
{
   swap();
   exit;
}

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
