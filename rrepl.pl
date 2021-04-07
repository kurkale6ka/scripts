#! /usr/bin/env perl

# Perl regex REPL
#
# todo:
#  - sanitize input (chroot, ..., or warn)
#  - mX...X for matching

use v5.22;
use warnings;
use open qw/:std :encoding(UTF-8)/;
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $gcstring;

BEGIN
{
   use Encode;
   Encode -> import ('decode');
   @ARGV = map { decode('UTF-8', $_, Encode::FB_CROAK | Encode::LEAVE_SRC) } @ARGV;

   if (@ARGV > 1 and grep /^--?v(e(r(b(o(se?)?)?)?)?)?$/n, @ARGV)
   {
      require re;
      re -> import ('debug');
   }

   if (system ('perldoc -l Unicode::GCString 1>/dev/null 2>&1') == 0)
   {
      require Unicode::GCString;
      $gcstring = 1;
   }
}

my ($GRAY, $PINK) = map {color "ansi$_"} (242, 205);

my $help = << '-------';
Perl regex REPL

rr [string] [regex] # without arguments reads multiline text from STDIN
rr /regex/

--string,  -s : force string
--verbose, -v : enable regex debug mode

* in the REPL loop the regex format is regex/flags
* \n can be used in string (remember to protect from shell)
* install Unicode::GCString for better underlining (^^^) of wide characters
-------

# Options
GetOptions (
   's|string'  => \my $string,
   'v|verbose' => sub {},
   'h|help'    => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

# 2 args max
die $help if @ARGV > 2;

# Globals
my ($str, $reg);

my $flags = qr/[msixpodualngc]/;
my $regex_arg  = qr% ^/ (.+?)     (?<!\\) /($flags*)   $ %x;
my $regex_repl = qr%    (.+?) (?: (?<!\\) /($flags+) )?$ %x; # /flags cannot be preceded by \

sub validate_regex
{
   $reg =~ s#(?<!\\)\\$#\\\\#g; # an eol \ would break the below =~ test

   if ($reg =~ /$regex_repl/)
   {
      # FIXME? \\/\ (/ preceded by \ but not actually escaped)
      if ($1 =~ m#(?<!\\)/#)
      {
         warn RED.'/s need to be escaped'.RESET, "\n";
      }
      if ($reg = eval (defined $2 ? "qr/$1/$2" : defined $1 ? "qr/$1/" : ''))
      {
         return 1;
      } else {
         warn RED.'not a valid regex'.RESET, "\n";
      }
   } else {
      warn RED."not a valid regex: $reg".RESET, "\n";
   }

   return 0;
}

# Arguments
if (@ARGV == 1)
{
   # rr scalar
   if ($string or $ARGV[0] !~ /$regex_arg/)
   {
      $str = $ARGV[0];
      repl();
   }
   else # rr /regex/
   {
      # remove //s to turn $regex_arg into $regex_repl
      $reg = substr $ARGV[0], 1;
      $reg =~ s#/$##;
      repl ('regex') if validate_regex $reg;
   }
}
elsif (@ARGV == 2) # rr scalar regex
{
   ($str, $reg) = @ARGV;
   exit 1 unless validate_regex $reg;
   match();
}
elsif (@ARGV == 0) # rr
{
   say $PINK.'multiline text (EOF with ^d):'.RESET;
   chomp (my @str = <STDIN>);
   $str = join "\n", @str;
   repl();
}

sub repl
{
   my $term = Term::ReadLine->new ('Regex REPL');
   $term->ornaments (0);
   my $OUT = $term->OUT || \*STDOUT;

   my $prompt = CYAN.(@_?'$scalar':'/regex/').'>>'.RESET.' ';

   while (defined ($_ = $term->readline ($prompt)))
   {
      next unless length; # empty prompt>>

      $_ = decode('UTF-8', $_, Encode::FB_CROAK | Encode::LEAVE_SRC);

      if (@_) # rr /regex/
      {
         chomp ($str = $_);
      } else {
         chomp ($reg = $_);
         next unless validate_regex $reg;
      }

      match();
   }
}

sub match
{
   $str =~ s/\\n/\n/g; # swap \n with real newlines ...

   if ($str =~ /$reg/)
   {
      my ($pre, $match, $post) = ($`, $&, $');

      s/\n/\\n/g foreach ($pre, $match, $post); # ... and back

      # info: pre, match, post
      my @match = (pre => $pre, match => GREEN.$match.RESET, post => $post);

      my @info;
      while (my ($key, $val) = splice @match, 0, 2)
      {
         next unless $val;
         $val = $GRAY.$val.RESET unless $key eq 'match';
         push @info, $PINK.$key.RESET.': '.$val;
      }

      my $underline;
      if ($gcstring)
      {
         $underline = ' ' x Unicode::GCString->new($pre)->columns . '^' x Unicode::GCString->new($match)->columns;
      } else {
         $underline = ' ' x length($pre) . '^' x length($match);
      }

      s/\\n/BLUE.BOLD.$&.RESET/eg foreach ($pre, $post); # newlines in blue

      # show match
      say $pre.GREEN.$match.RESET.$post, ' (', join (', ', @info), ')';
      say $underline;
   }
   else {
      warn RED.'no match'.RESET, "\n";
   }
}
