#! /usr/bin/env perl

# Sort camera shots into timestamped folders
#
# TODO: images in pink if err/warn
#       -w for warnings but disable by default?
#       global $dry used inside lib_import. fix?

use strict;
use warnings;
use feature 'say';
use lib '/usr/local/Cellar/exiftool/11.85/libexec/lib'; # TODO: get rid of this
use Image::ExifTool ':Public';
use File::Basename 'fileparse';
use Term::ANSIColor qw/:constants color/;
use Getopt::Long qw/GetOptions :config no_ignore_case/;

# Location where pictures get uploaded
my $source = glob '"~/Dropbox/Camera Uploads"';

# Images library
my $destination = glob '~/Dropbox/pics';

my %messages = (
   title  => 'sort camera shots into timestamped folders',
   import => 'import into the images library',
);

my $BLUE  = color('ansi69');
my $GREEN = color('green');
my $BOLD  = color('bold');
my $RESET = color('reset');

sub help
{
   print <<HELP;
${BOLD}SYNOPSIS${RESET}

   pics    [-s ${BLUE}src${RESET}] [-d ${BLUE}dst${RESET}] [-n] [-v] : ${GREEN}$messages{title}${RESET}
   pics -i [-s ${BLUE}src${RESET}] [-d ${BLUE}dst${RESET}] [-n] [-v] : ${GREEN}$messages{import}${RESET}

   pics                [img ...|${BLUE}dir${RESET}] : ${GREEN}show tags${RESET}
   pics -t [tag[,...]] [img ...|${BLUE}dir${RESET}] :

${BOLD}OPTIONS${RESET}

   --source,      -s
   --destination, -d
                  -n (dry-run)
   --verbose,     -v
   --(no-)import, -i
   --tags,        -t
HELP
   exit;
}

# Options
my ($dry, $src, $dst, $import, $verbose, $tags);

GetOptions (
   'n'             => \$dry,
   'source=s'      => \$src,
   'destination=s' => \$dst,
   'import!'       => \$import,
   'verbose'       => \$verbose,
   'tags:s'        => \$tags,
   'help'          => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

$src and      $source = $src;
$dst and $destination = $dst;

# Checks
unless (defined $tags)
{
   # pics img ..., pics dir => implicit --tags
   if (@ARGV > 0)
   {
      if ($dry or $src or $dst or $verbose)
      {
         die RED.'When showing tags, no options are allowed'.RESET, "\n";
      } else {
         $tags = '';
      }
   } else {
      -d $source or die RED."Source missing: ${BLUE}$source".RESET, "\n";
   }
} elsif ($dry or $src or $dst or $verbose) {
   die RED.'When showing tags, no options are allowed'.RESET, "\n";
}

# Import
sub lib_import
{
   -d $destination or die RED."Destination missing: ${BLUE}$destination".RESET, "\n";

   my @years = grep -d $_, glob "'$source/[0-9][0-9][0-9][0-9]'";
   @years or return;

   my $options = 'a';
   $options .= 'i' if $dry or $verbose;
   $options .= 'n' if $dry;

   system qw/rsync --remove-source-files --partial/, "-$options", @years, $destination;

   # delete source years + months after a successful transfer
   if ($? == 0 and not $dry)
   {
      foreach my $year (@years)
      {
         foreach (glob "'$year/{January,February,March,April,May,June,July,August,September,October,November,December}'")
         {
            next unless -d $_;
            rmdir $_ or die "$_: $!\n";
         }
         rmdir $year or die "$year: $!\n";
      }
   }
}

lib_import if $import;

# ExifTool object
my $exifTool = new Image::ExifTool;

$exifTool->Options (
   Sort       => 'Group1',
   DateFormat => '%d %b %Y, %H:%M',
);

# Show tags
# TODO:
# allow folder or . as an arg
if (defined $tags)
{
   my @tags;

   if ($tags eq '')
   {
      # TODO: check *keyword* *comment* work
      # exiftool -G -S -a -'*keyword*' -subject -title -'*comment*' -make -model -createdate -datetimeoriginal
      @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
   } else {
      # exiftool -G -S -a -tag1 ... -tagn
      # system qw/exiftool -G -S -a/, map ("-$_", @tags), $img;
      @tags = split /\s*,\s*/, $tags;
   }

   # if (@ARGV == 0)
   # {
   #    foreach (glob '"./*"')
   #    {
   #    }
   # }

   my $img = shift;

   if (-e $img)
   {
      my $info = $exifTool->ImageInfo($img, \@tags);

      if (exists $info->{Error})
      {
         warn RED, $info->{Error}, RESET, "\n";
      }

   } else {
      warn RED."File not found: $img".RESET, "\n";
   }

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

# Sort camera shots
unless (defined $tags or $import)
{
   say GREEN, ucfirst $messages{title}, RESET;
   say   '-' x length $messages{title};

   my $filename = $dry ? 'testname' : 'filename';

   # # the last valid -$filename<$createdate supersedes the others:
   # system ('exiftool', '-q', '-q',
   #    # '-p', '"$directory/$filename": $createdate - $datetimeoriginal', '-if', '$createdate !~ $datetimeoriginal',
   #    '-d', "$source/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
   #    "-$filename<\$createdate.%le",
   #    "-$filename<\$createdate \${make;}.%le",
   #    $source
   # );

   my %cdates;

   # TODO: ask on forum about efficiency compared to exiftool on dir
   foreach my $image (glob "'$source/*'")
   {
      if (-f $image)
      {
         # Compare CreateDate and DateTimeOriginal
         my $dates = $exifTool->ImageInfo($image, qw/CreateDate DateTimeOriginal/, {DateFormat => '%d-%b-%Y %Hh%Mm%S'});

         my $cdate = $dates->{CreateDate};
         my $ddate = $dates->{DateTimeOriginal};
         $cdate //= '';
         $ddate //= '';

         if ($cdate ne $ddate)
         {
            warn "$image ", YELLOW."CreateDate ($cdate) differs from DateTimeOriginal ($ddate)".RESET, "\n";
            # TODO: next;
         }

         # Add -num (%c) before extension for images having the same Createdate
         my $num = '';
         if ($cdate)
         {
            $cdates{$cdate}++;
            $num = '-'.($cdates{$cdate}-1) if $cdates{$cdate} > 1;
         }

         # Sort camera shots
         my $info;
         my ($basename, $dirs, $ext) = fileparse($image, qr/\.[^.]+$/);

         if ($exifTool->GetValue('Make'))
         {
            $info = $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("'.$source.'/%Y/%B/%d-%b-%Y %Hh%Mm%S")} ${make;}'.$num.lc($ext));
         } else {
            $info = $exifTool->SetNewValuesFromFile($image, $filename.'<${createdate#;DateFmt("'.$source.'/%Y/%B/%d-%b-%Y %Hh%Mm%S")}'.$num.lc($ext));
         }

         # Errors while sorting
         unless (exists $info->{Warning} or exists $info->{Error})
         {
            my $result = $exifTool->WriteInfo($image);

            # Errors while writing
            unless ($result == 1)
            {
               if ($exifTool->GetValue('Warning'))
               {
                  warn "Warning writing ${basename}$ext ", YELLOW, $exifTool->GetValue('Warning'), RESET, "\n";
               }
               if ($exifTool->GetValue('Error'))
               {
                  warn "Error writing ${basename}$ext ", RED, $exifTool->GetValue('Error'), RESET, "\n";
               }
            }
         } else {
            if (exists $info->{Warning})
            {
               warn "Warning moving ${basename}$ext ", YELLOW, $info->{Warning}, RESET, "\n";
            }
            if (exists $info->{Error})
            {
               warn "Error moving ${basename}$ext ", RED, $info->{Error}, RESET, "\n";
            }
         }
      }
   }

   # Import unless --no-import
   unless (defined $import or $dry)
   {
      print "\n", GREEN, ucfirst $messages{import}, RESET, ' (y/n)? ';

      if (<STDIN> =~ /y(es)?/in)
      {
         say '-' x length $messages{import} if $verbose;
         lib_import;
      }
   }
}
