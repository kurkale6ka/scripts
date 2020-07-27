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
   'p|prefix=s'  => \$prefix,
   'a|archive=s' => \$archive,
   'h|help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

unless ($archive)
{
   # select the most recently downloaded package
   ($archive) = sort { (stat $b)[9] <=> (stat $a)[9] } glob "~/Downloads/*$suffix";

   if ($archive)
   {
      print 'Found ', RED.basename($archive).RESET, ' Continue (y/n)? ';
      <STDIN> =~ /y(es)?/ni or exit;
   } else {
      die RED.'No package found'.RESET, "\n";
   }
}

system ('mv', $archive, $prefix) == 0
   or die "$!\n";

chdir $prefix;

system ('tar', 'zxf', basename $archive) == 0
   or die "$!\n";

unlink basename $archive;

my $pkg = basename ($archive, $suffix);
chdir $pkg;

system (qw/makepkg -s/) == 0
   or die "$!\n";

# as dep
# system qw/pacman --asdeps -U/, "$pkg.tar.xz";

# Install
system qw/pacman -U/, "$pkg.tar.xz"
   or die "$!\n";
