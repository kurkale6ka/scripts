#! /usr/bin/env perl

# Sort camera shots into timestamped folders
#
# Usage: pics.pl [-n|-s|-d|-i[v]|-t]
#
# TODO: import sub, y/n after main
#       images in pink if err/warn
#       arg img or folder, use -t

use strict;
use warnings;
use feature 'say';
# TODO: get rid of this
use lib '/usr/local/Cellar/exiftool/11.85/libexec/lib';
use Image::ExifTool ':Public';
use File::Basename 'fileparse';
use Term::ANSIColor ':constants';
use Getopt::Long qw/GetOptions :config no_ignore_case/;

my $description = 'sort camera shots into timestamped folders';

# Folder where pictures get uploaded
my $source = glob '"~/Dropbox/Camera Uploads"';

# Images library folder
my $destination = glob '~/Dropbox/pics';

sub help
{
   print <<HELP;
Usage:

   pics    [-s src] [-d dst] [-n] [-v] : $description
   pics -i [-s src] [-d dst] [-n] [-v] : import into the images library

   pics                 [img ...|dir] : show tags
   pics -t [tag [,...]] [img ...|dir] :

options long names

   --source,      -s
   --destination, -d
                  -n (dry-run)
   --verbose,     -v
   --import,      -i
   --tags,        -t
HELP
   exit; # TODO: die if $? != 0
}

# Options
my ($dry, $import, $verbose, $tags);

GetOptions (
   'n'             => \$dry,
   'source=s'      => \$source,
   'destination=s' => \$destination,
   'import'        => \$import,
   'verbose'       => \$verbose,
   'tags:s'        => \$tags,
   'help'          => \&help
) or die RED."Error in command line arguments\n".RESET;

# Checks
# TODO: move to main/import?
# warn if incompatible options
unless (defined $tags)
{
   -d $source or die RED."Uploads folder missing\n".RESET;
}

sub lib_import {
   -d $destination or die RED."Destination folder missing\n".RESET;

   my @years = grep -d $_, glob "'$source/[0-9][0-9][0-9][0-9]'";

   system qw/rsync --remove-source-files --partial -ai/, @years, $destination;

   # delete source years + months after a successful transfer
   if ($? == 0)
   {
      foreach my $year (@years)
      {
         foreach (glob "$year/{January,February,March,April,May,June,July,August,September,October,November,December}")
         {
            if (-d $_)
            {
               rmdir $_ or die "$_: $!\n";
            }
         }
         rmdir $year or die "$year: $!\n";
      }
   }
}

# Import
if ($import)
{
   lib_import;
}

my $exifTool = new Image::ExifTool;

$exifTool->Options(
   Sort => 'Group1',
   DateFormat => '%d %b %Y, %H:%M',
);

# Show tags
# TODO:
# allow folder or . as an arg
if (defined $tags)
{
   @ARGV > 0 or die "You need images with --tags\n";

   my $img = shift;
   my @tags;

   if ($tags eq '')
   {
      # TODO: check *keyword* *comment* work
      # exiftool -G -S -a -'*keyword*' -subject -title -'*comment*' -make -model -createdate -datetimeoriginal
      @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
   } else {
      # TODO: coma separated?
      # if all <=> exiftool -G -S -a
      @tags = ($tags);
   }

   $exifTool->ImageInfo($img, \@tags);

   # TODO: change display to
   # Group1
   #   tag: ...
   # Group2
   #   tag: ...
   foreach my $tag (@tags)
   {
      next unless $exifTool->GetValue($tag);
      printf "[%s] %24s: %s\n", $exifTool->GetGroup($tag, 0), $tag, GREEN.$exifTool->GetValue($tag).RESET;
   }
}

# Main
# TODO:
# - fix %c
# - dry run by default?
unless (defined $tags or $import)
{
   say GREEN, ucfirst $description, RESET;
   say '-' x length $description;

   my $filename = 'testname';
   my %dates;

   # TODO: ask on forum about efficiency compared to exiftool on dir
   foreach my $image (glob "'$source/*'")
   {
      if (-f $image)
      {
         my ($basename, $dirs, $suffix) = fileparse($image, qr/\.[^.]+$/);
         my ($info, $result);

         my $date;
         my $date_ref = $exifTool->ImageInfo($image, 'CreateDate', {DateFormat => '%d-%b-%Y %Hh%Mm%S'});

         my $suf = '';
         if ($date = $date_ref->{CreateDate})
         {
            $dates{$date}++;
            if ($dates{$date} > 1)
            {
               $suf = $dates{$date} - 1;
               $suf = "-$suf";
            }
         }

         if ($exifTool->GetValue('Make'))
         {
            $info = $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("'.$source.'/%Y/%B/%d-%b-%Y %Hh%Mm%S")} ${make;}'.$suf.lc($suffix));
         } else {
            $info = $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("'.$source.'/%Y/%B/%d-%b-%Y %Hh%Mm%S")}'.$suf.lc($suffix));
         }

         # Errors while sorting images
         unless (exists $info->{Warning} or exists $info->{Error})
         {
            $result = $exifTool->WriteInfo($image);

            # Errors while writing
            unless ($result == 1)
            {
               if ($exifTool->GetValue('Warning'))
               {
                  warn "Warning writing $basename ", YELLOW, $exifTool->GetValue('Warning'), RESET, "\n";
               }
               if ($exifTool->GetValue('Error'))
               {
                  warn "Error writing $basename ", RED, $exifTool->GetValue('Error'), RESET, "\n";
               }
            }
         } else {
            if (exists $info->{Warning})
            {
               warn "Warning moving $basename ", YELLOW, $info->{Warning}, RESET, "\n";
            }
            if (exists $info->{Error})
            {
               warn "Error moving $basename ", RED, $info->{Error}, RESET, "\n";
            }
         }
      }
   }

   # lib_import ?
}
