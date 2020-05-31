#! /usr/bin/env perl

# Move camera shots to timestamped folders
#
# Usage: pics [-n|-s[v]|-i|-I]

use strict;
use warnings;
use feature 'say';
use Time::Piece;
use File::Path 'make_path';
use lib '/usr/local/Cellar/exiftool/11.85/libexec/lib';
use Image::ExifTool ':Public';
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
   foreach my $upload (glob "$uploads/*")
   {
      system qw(rsync -aiPn), $upload, $pics if -d $upload;
   }
}

my @tags = ('CreateDate');

if ($info)
{
   # TODO: *...*
   # exiftool -G -S -a -'*keyword*' -subject -title -'*comment*' -make -model -createdate -datetimeoriginal
   @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
}
elsif ($Info)
{
   @tags = ('All'); # exiftool -G -S -a
}

my $image = shift;

my $exifTool = new Image::ExifTool;

$exifTool->Options(
   Sort => 'Group1',
   DateFormat => '%Y/%B/%e-%b-%Y %H.%M.%S%%-c.%le',
);

$exifTool->ImageInfo($image, \@tags);

# TODO:
# Group
#   tag1: val1
#   tag2: val2
foreach my $tag (@tags)
{
   printf "[%s] %24s: %s\n", $exifTool->GetGroup($tag, 0), $tag, GREEN.$exifTool->GetValue($tag).RESET;
}

say YELLOW.'Manage media files'.RESET, ':';

my $time = Time::Piece->new;
make_path $time->strftime('%Y/%B');

# $exifTool->SetNewValue('FileName', $createdate);
my $result = $exifTool->WriteInfo($image, "");
my $errorMessage = $exifTool->GetValue('Error');
say $errorMessage;

# The last valid '-filename<$createdate' supersedes the others:
# $make will be used only if it exists!
# my $result = $exifTool->SetFileName($image, 'FileName<CreateDate', 'Test');
# exiftool -$nametag'<$createdate.%le'          -d $uploads'/%Y/%B/%Y-%m-%d %H.%M.%S%%-c' \
#          -$nametag'<$createdate ${make;}.%le' -d $uploads'/%Y/%B/%Y-%m-%d %H.%M.%S%%-c' \
#          $uploads

__DATA__

## Actions
# TODO: re-enable dates_ok
# local dates_ok=1 # success: $createdate == $datetimeoriginal

date_cmp() {
   touch /tmp/pics_compare
   print -P '%F{yellow}Files with different -createdate and -datetimeoriginal%f:'
   exiftool -p '"$directory/$filename": $createdate - $datetimeoriginal' -if '$createdate !~ $datetimeoriginal' $uploads # global variable
   # dates_ok=$? # global variable!
}

local nametag=filename # renaming will happen unless -n supplied

case $action in

   (dry_run)
      nametag=testname
      [[ ! -e /tmp/pics_compare ]] && date_cmp
      ;;

   (sync)
      [[ ! -d $pics ]] && { print -P '%F{red}Pictures folder not defined%f' 1>&2; return 2 }

      # dry runs
      if ((verbose))
      then
         rsync -ain $uploads/*(/) $pics
      else
         rsync -ain $uploads/*(/) $pics | grep -v 'f+++++++++'
      fi

      # commit
      if (($? == 0)) then
         read '?apply? (y/n) '
         if [[ $REPLY == (y|yes) ]]
         then
            if rsync -a $uploads/*(/) $pics
            then
               rm -r $uploads/*(/)
            fi
         fi
      fi
      return

## Manage media files
[[ ! -e /tmp/pics_compare ]] && date_cmp

# if ((dates_ok)) || [[ $nametag == testname ]]
# then

# The last valid '-filename<$createdate' supersedes the others:
# $make will be used only if it exists!
print -P '%F{yellow}Manage media files%f:'
exiftool -$nametag'<$createdate.%le'          -d $uploads'/%Y/%B/%Y-%m-%d %H.%M.%S%%-c' \
         -$nametag'<$createdate ${make;}.%le' -d $uploads'/%Y/%B/%Y-%m-%d %H.%M.%S%%-c' \
         $uploads

[[ $nametag == filename && -w /tmp/pics_compare ]] && rm /tmp/pics_compare

# fi
