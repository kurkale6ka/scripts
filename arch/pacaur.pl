#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use autodie;
use File::Glob ':bsd_glob';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use File::Basename 'basename';
use File::Path 'make_path';
use List::Util 'any';

my $BLUE = color('ansi69');
my $CYAN = color('ansi45');
my $S = color('bold');
my $R = color('reset');

# EUID check
$> or die RED.'Not allow to run as root'.RESET, "\n";

# Help
sub help() {
   print <<MSG;
${S}SYNOPSIS${R}
${S}OPTIONS${R}
${S}DESCRIPTION${R}
MSG
   exit;
}

# Arguments
my $prefix = '/usr/local';
my $archive;
my $suffix = '.tar.gz';

GetOptions (
   'p|prefix'  => \$prefix,
   'a|archive' => \$archive,
   'h|help'    => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

unless ($archive)
{
   # select the most recently downloaded package
   ($archive) = sort { (stat $b)[9] <=> (stat $a)[9] } glob "~/Downloads/*$suffix";

   if ($archive)
   {
      print "Found $archive. continue (y/n)? ";
      die RED.'Abort'.RESET, "\n" unless <STDIN> =~ /y(es)?/ni;
   } else {
      die RED.'No package found'.RESET, "\n";
   }
}

my $pkg = basename ($archive, $suffix);

if (system ('mv', $archive, $prefix) == 0)
{
   if (system ('tar', 'zxf', $archive) == 0)
   {
      unlink "$prefix/$archive";

      chdir $pkg;

      system (qw/makepkg -s/) == 0 or die "$!\n";

      # as dep
      # system qw/pacman --asdeps -U/, "$pkg.tar.xz";

      # Install
      system qw/pacman -U/, "$pkg.tar.xz";
   }
}
