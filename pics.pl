#! /usr/bin/env perl

# Sort camera shots into timestamped folders
#
# Usage: pics [-n|-s[v]|-i|-I]

use strict;
use warnings;
use feature 'say';
use lib '/usr/local/Cellar/exiftool/11.85/libexec/lib';
use Image::ExifTool ':Public';
use File::Basename 'fileparse';
use Term::ANSIColor ':constants';
use Getopt::Long qw/GetOptions :config no_ignore_case/;

# Source folder where pictures get uploaded
my $uploads = glob '"~/Dropbox/Camera Uploads"';

# Destination folder
my $pics = glob '~/Dropbox/pics';

-d $uploads or die RED.'Uploads folder not defined'.RESET, "\n";

sub help
{
say <<HELP;
   pics [-n (dry run)]           : manage media files
   pics -s[v(erbose)]            : sync
   pics -i|I {file...|directory} : get info
HELP
   exit; # TODO: die if $? != 0
}

# Options
my ($dry, $sync, $verbose, $info, $Info);

GetOptions (
   'dry|n'   => \$dry,
   'sync'    => \$sync,
   'verbose' => \$verbose,
   'info'    => \$info,
   'Info'    => \$Info,
   'help'    => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Arguments
say 'dry' if $dry;
say 'verbose' if $verbose;

if ($sync)
{
   foreach (glob "$uploads/*")
   {
      system qw(rsync -aiPn), $_, $pics if -d $_;
   }
}

my $image = shift;
my ($basename, $dirs, $suffix) = fileparse($image, qr/\.[^.]+$/);

my $exifTool = new Image::ExifTool;

$exifTool->Options(
   Sort => 'Group1',
   DateFormat => '%e %B, %H:%M',
);

# Info
if ($info or $Info)
{
   my @tags;

   if ($info)
   {
      # TODO: *...*
      # exiftool -G -S -a -'*keyword*' -subject -title -'*comment*' -make -model -createdate -datetimeoriginal
      @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
   } else {
      # exiftool -G -S -a
      @tags = ('All');
   }

   $exifTool->ImageInfo($image, \@tags);

   # TODO: change display to
   # Group1
   #   tag1: val1
   #   tag2: val2
   # Group2
   #   tag: ...
   foreach my $tag (@tags)
   {
      next unless $exifTool->GetValue($tag);
      printf "[%s] %24s: %s\n", $exifTool->GetGroup($tag, 0), $tag, GREEN.$exifTool->GetValue($tag).RESET;
   }
}

say YELLOW.'Sort camera shots into timestamped folders'.RESET, ':';

my $filename = 'testname';

if ($exifTool->GetValue('Make'))
{
   $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("%Y/%B/%e-%b-%Y %Hh%Mm%S")} ${make;}'.lc($suffix));
} else {
   $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("%Y/%B/%e-%b-%Y %Hh%Mm%S")}'.lc($suffix));
}

my $result = $exifTool->WriteInfo($image);

my $errorMessage = $exifTool->GetValue('Error');
say $errorMessage if $errorMessage;
