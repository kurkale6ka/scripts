#! /usr/bin/env perl

# Sort camera shots into timestamped folders
#
# TODO: -w for warnings but disable by default?
#       show img --> img1 if verbose (like testname)
#       global $dry used inside lib_import. fix?
#       --checks?

use strict;
use warnings;
use feature 'say';
use File::Basename 'fileparse';
use Term::ANSIColor qw/:constants color/;
use Getopt::Long qw/GetOptions :config bundling/;

# Location where pictures get uploaded
my $source = glob '"~/Dropbox/Camera Uploads"';

# Images library
my $destination = glob '~/Dropbox/pics';

my %messages = (
   title  => 'sort camera shots into timestamped folders',
   import => 'import into the images library',
);

my $BOLD  = color('bold');
my $BLUE  = color('ansi69');
my $GREEN = color('green');
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
   --dry-run,     -n
   --verbose,     -v (-vv for more details)
   --(no-)import, -i
   --tags,        -t
HELP
   exit;
}

# Options
my ($dry, $src, $dst, $import, $verbose, $tags);

GetOptions (
   'n|dry-run'       => \$dry,
   's|source=s'      => \$src,
   'd|destination=s' => \$dst,
   'i|import!'       => \$import,
   'v|verbose+'      => \$verbose,
   't|tags:s'        => \$tags,
   'h|help'          => \&help
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

# Show tags
if (defined $tags)
{
   my @tags;

   if ($tags eq '')
   {
      # list of tags I am mostly interested in
      @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
   } elsif ($tags =~ /^d(ates)?$/in) {
      @tags = ('alldates');
   } elsif ($tags =~ /^a$/in) {
      @tags = ('all');
   } else {
      @tags = split /\s*,\s*/, $tags;
   }

   # very short (-S) output format for a single tag, short (-s) otherwise
   if (@tags == 1 and $tags[0] !~ /all/i)
   {
      system qw/exiftool -G -S -a/, map ("-$_", @tags), @ARGV > 0 ? @ARGV : '.';
   } else {
      system qw/exiftool -G -s -a/, map ("-$_", @tags), @ARGV > 0 ? @ARGV : '.';
   }
}

# Sort camera shots
unless (defined $tags or $import)
{
   say GREEN, ucfirst $messages{title}, RESET;
   say   '-' x length $messages{title};

   my $filename = $dry ? 'testname' : 'filename';

   my @quiet;
   unless ($verbose)
   {
      @quiet = qw/-q -q/;
   } elsif ($verbose == 1) {
      @quiet = ('-q');
   }

   # see 'RENAMING EXAMPLES' in 'man exiftool'
   # the last valid -$filename<$createdate supersedes the others
   system ('exiftool', @quiet,
      # dates match or a single one only set
      '-if', 'not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)',
      '-d', "$source/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
      "-$filename<\$datetimeoriginal.%le",
      "-$filename<\$datetimeoriginal \${make;}.%le",
      "-$filename<\$createdate.%le",
      "-$filename<\$createdate \${make;}.%le",
      $source
   );

   die RED.'Encountered errors while sorting camera shots'.RESET, "\n" if $? != 0;

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
