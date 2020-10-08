#! /usr/bin/env perl

# Sort camera shots into timestamped folders
#
# TODO: --checks?

use strict;
use warnings;
use feature 'say';
use File::Glob ':bsd_glob';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use List::Util 'all';

# Location where pictures get uploaded
my $source = glob '~/Dropbox/Camera Uploads';

# Images library
my $destination = glob '~/Dropbox/pics';

my %messages = (
   title  => 'sort camera shots into timestamped folders',
   import => 'import into the images library',
);

my $BLUE  = color('ansi69');
my $GRAY  = color('ansi242');
my $GREEN = color('green');
my $S = color('bold');
my $R = color('reset');

sub help
{
   print <<MSG;
${S}SYNOPSIS${R}

   pics    [-s ${BLUE}src${R}] [-d ${BLUE}dst${R}] [-n] [-v] : ${GREEN}$messages{title}${R}
   pics -i [-s ${BLUE}src${R}] [-d ${BLUE}dst${R}] [-n]      : ${GREEN}$messages{import}${R}

   pics                [img ...|${BLUE}dir${R}] [-v] : ${GREEN}show tags${R}
   pics -t [tag[,...]] [img ...|${BLUE}dir${R}] [-v] :

${S}OPTIONS${R}

   --source,      -s
   --destination, -d
   --dry-run,     -n
   --verbose,     -v (-vv for more details)
   --(no-)import, -i
   --tags,        -t (-td[ates], -ta[ll])
MSG
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
      if ($dry or $src or $dst)
      {
         die RED.'When showing tags, no options are allowed'.RESET, "\n";
      } else {
         $tags = '';
      }
   } else {
      -d $source or die RED."Source missing: ${BLUE}$source".RESET, "\n";
   }
} elsif ($dry or $src or $dst) {
   die RED.'When showing tags, no options are allowed'.RESET, "\n";
}

# Import
sub lib_import
{
   -d $destination or
   die RED."Destination missing: ${BLUE}$destination".RESET, "\n";

   my @years = grep -d $_, glob "$source/[0-9][0-9][0-9][0-9]";
   @years or return;

   print "\n" unless $import;
   say GREEN, ucfirst $messages{import}, RESET;
   say   '-' x length $messages{import};

   # list images being imported
   open my $sync, '-|',
   qw/rsync --remove-source-files --partial -ain/, @years, $destination
      or die RED.'Test import failed'.RESET, "\n";

   while (<$sync>)
   {
      # display dirs in blue
      s@(?<=\s).*/@${BLUE}$&${R}@;

      # warn if the size has changed
      s/^...s...../RED.$&.RESET/e;

      print;
   }

   $dry and return;

   # commit the import
   print "\nConfirm (y/n)? ";

   if (<STDIN> =~ /y(es)?/in)
   {
      system qw/rsync --remove-source-files --partial -a/, @years, $destination;
      $? == 0 or return;

      # delete source years + months after a successful transfer
      foreach my $year (@years)
      {
         foreach (glob "$year/{January,February,March,April,May,June,July,August,September,October,November,December}")
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
   my (@tags, @options);

   # tags I am mostly interested in
   if ($tags eq '') {
      @tags = qw/*keyword* subject title *comment* make model createdate datetimeoriginal/;
   }
   # -td
   elsif ($tags =~ /^d(ates)?$/in) {
      @tags = ('alldates');
   }
   # -ta
   elsif ($tags =~ /^a$/in) {
      @tags = ('all');
   }
   else {
      @tags = split /\s*,\s*/, $tags;

      # check for 'invalid' (1 letter) tags
      if (my @bad_tags = map "-$_", grep {/^.$/} @tags)
      {
         die RED.'Invalid tag', @bad_tags == 1 ? ': ' : 's: ',
         join (', ', @bad_tags), RESET, "\n";
      }
   }

   # short or shortest output format
   @options = ('-s');
   @options = ('-S') if @tags == 1 and $tags[0] !~ /all/i;

   # recurse in dirs
   push @options, '-r' if all {-d $_} @ARGV;

   # show command
   if ($verbose)
   {
      my   @tg = map {/\*/ ? "-'$_'" : "-$_"} @tags;
      my @args = map {/\s/ ?  "'$_'" :   $_ } @ARGV;

      say YELLOW."exiftool -a -G @options @tg ", @ARGV > 0 ? "@args" : '.', RESET;
   }

   system qw/exiftool -a -G/, @options, map ("-$_", @tags), @ARGV > 0 ? @ARGV : '.';
}

# Sort camera shots
unless (defined $tags or $import)
{
   say GREEN, ucfirst $messages{title}, RESET;
   say   '-' x length $messages{title};

   my @quiet = qw/-q -q/;

   if ($verbose)
   {
      pop @quiet for 1..$verbose;
   }

   # test run
   open (my $sort, '-|', 'exiftool', @quiet,
      '-if', 'not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)',
      '-d', "$source/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
      '-testname<$datetimeoriginal.%le',
      '-testname<$datetimeoriginal ${make;}.%le',
      '-testname<$createdate.%le',
      '-testname<$createdate ${make;}.%le',
      $source
   ) or die RED.'Test sorting of camera shots failed'.RESET, "\n";

   while (<$sort>)
   {
      s@$source/?@@g;
      s@--> '(.*/)@$GRAY-->$R '${BLUE}$1${R}@;
      print;
   }

   # commit
   unless ($dry)
   {
      # see 'RENAMING EXAMPLES' in 'man exiftool'
      system ('exiftool', '-q', '-q',
         # dates match or a single one only set
         '-if', 'not ($createdate and $datetimeoriginal and $createdate ne $datetimeoriginal)',
         '-d', "$source/%Y/%B/%d-%b-%Y %Hh%Mm%S%%-c",
         # the last valid -filename<$createdate supersedes the others
         '-filename<$datetimeoriginal.%le',
         '-filename<$datetimeoriginal ${make;}.%le',
         '-filename<$createdate.%le',
         '-filename<$createdate ${make;}.%le',
         $source
      );
      $? == 0 or die RED.'Sorting of camera shots failed'.RESET, "\n";

      # Import unless --no-import
      lib_import unless defined $import;
   }
}
