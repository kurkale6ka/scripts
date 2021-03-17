#! /usr/bin/env perl

# Perl regex REPL
#
# todo:
#  - sanitize input (chroot, ..., or warn)

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

   unless (system 'perldoc -l Unicode::GCString 1>/dev/null 2>&1')
   {
      require Unicode::GCString;
      $gcstring = 1;
   }
}

use v5.12;
use warnings;
use open qw/:std :encoding(UTF-8)/;
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long 'GetOptions';

my $GRAY = color 'ansi242';
my $PINK = color 'ansi205';

my $help = << 'MSG';
Perl regex REPL

rr              : read multiline text from STDIN
rr string
rr string regex
rr regex

--verbose, -v : enable regex debug mode

\n can be used in string (remember to protect from shell)
flags can be appended to regex with /regex/flags (1st / optional)
install Unicode::GCString for better underlining (^^^) of wide characters
MSG

# Options
GetOptions (
   'verbose' => sub {},
   'help'    => sub {print $help; exit}
) or die RED.'Error in command line arguments'.RESET, "\n";

# 2 args max
die $help if @ARGV > 2;

# globals
my ($str, $reg);
my $regex_arg = qr! ^/?(.*?)/(.*) !x;

# Arguments
if (@ARGV == 1)
{
   # rr scalar
   unless ($ARGV[0] =~ /$regex_arg/)
   {
      $str = $ARGV[0];
      repl();
   }
   else # rr /regex/
   {
      $reg = eval "qr/$1/$2"; # get flags
      repl('regex');
   }
}
elsif (@ARGV == 2) # rr scalar regex
{
   ($str, $reg) = @ARGV;
   $reg = eval "qr/$1/$2" if $reg =~ /$regex_arg/;
   match();
}
elsif (@ARGV == 0) # rr
{
   say $PINK.'multiline text (EOF with ^d):'.RESET;
   chomp (my @str = <STDIN>);
   $str = join '\n', @str;
   repl();
}

sub repl
{
   my $term = Term::ReadLine->new('Regex REPL');
   $term->ornaments(0);
   my $OUT = $term->OUT || \*STDOUT;

   my $prompt = CYAN . (@_ ? '$scalar>> ' : '/regex/>> ') . RESET;

   while (defined ($_ = $term->readline($prompt)))
   {
      $_ = decode('UTF-8', $_, Encode::FB_CROAK | Encode::LEAVE_SRC);
      if (@_) # rr /regex/
      {
         chomp ($str = $_);
      } else {
         chomp ($reg = $_);
         $reg = eval "qr/$1/$2" if $reg =~ /$regex_arg/;
      }
      match();
   }
}

sub match
{
   return unless $str and $reg; # empty prompt>>
   $str =~ s/\\n/\n/g;

   if ($str =~ /$reg/)
   {
      my @info;
      my ($pre, $match, $post) = ($`, $&, $');
      s/\n/\\n/g foreach ($pre, $match, $post);

      # info: pre, match, post
      my @match = (pre => $pre, match => $match, post => $post);

      while (my ($key, $val) = splice @match, 0, 2)
      {
         next unless $val;
         $val = $key eq 'match' ? GREEN.$val.RESET : $GRAY.$val.RESET;
         push @info, $PINK.$key.RESET.': '.$val;
      }

      my $info = join ', ', @info;
      my $underline;

      unless ($gcstring)
      {
         $underline = ' ' x length($pre) . '^' x length($match);
      } else {
         $underline = ' ' x Unicode::GCString->new($pre)->columns . '^' x Unicode::GCString->new($match)->columns;
      }

      # color newlines in blue
      s/\\n/BLUE.BOLD.'\n'.RESET/eg foreach ($pre, $post);

      say $pre . GREEN.$match.RESET . $post, " ($info)";
      say $underline;
   }
   else {
      warn RED.'no match'.RESET, "\n";
   }
}
