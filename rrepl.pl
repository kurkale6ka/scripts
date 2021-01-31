#! /usr/bin/env perl

# Perl regex REPL
#
# Alternatively:
#   use re 'debug';
#   use diagnostics;
#   or use the debugger :-)
#
# todo: sanitize input (chroot, ..., or warn)

use strict;
use warnings;
use feature 'say';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $GRAY = color('ansi242');

my $help = << 'MSG';
Perl regex REPL

rr string
rr string regex
rr regex

\n can be used in string (remember to protect from shell)
flags can be appended to regex with /regex/flags (1st / optional)
MSG

# Options
GetOptions (
   'h|help' => sub {print $help; exit}
) or die RED.'Error in command line arguments'.RESET, "\n";

die $help unless @ARGV;

# globals
my ($str, $reg);
my $regex_arg = qr! ^/?(.*?)/(.*) !x;

# Arguments
if (@ARGV == 2) # rr scalar regex
{
   ($str, $reg) = @ARGV;
   $reg = eval "qr/$1/$2" if $reg =~ $regex_arg;
   match();
}
elsif (@ARGV == 1)
{
   # rr /regex/
   if ($ARGV[0] =~ $regex_arg)
   {
      $reg = eval "qr/$1/$2"; # get flags
      repl('regex');
      # rr scalar
   } else {
      $str = $ARGV[0];
      repl();
   }
}

sub repl
{
   my $term = Term::ReadLine->new('Regex REPL');
   $term->ornaments(0);
   my $OUT = $term->OUT || \*STDOUT;

   my $prompt = CYAN . (@_ ? '$scalar>> ' : '/regex/>> ') . RESET;

   while (defined ($_ = $term->readline($prompt)))
   {
      if (@_) # rr /regex/
      {
         chomp ($str = $_);
      } else {
         chomp ($reg = $_);
         $reg = eval "qr/$1/$2" if $reg =~ $regex_arg;
      }
      match();
   }
}

sub match
{
   return unless $str and $reg; # empty prompt>>
   $str =~ s/\\n/\n/g;

   if ($str =~ $reg)
   {
      my @info;
      my ($pre, $match, $post) = ($`, $&, $');
      s/\n/\\n/g foreach ($pre, $match, $post);

      my @match = (pre => $pre, match => $match, post => $post);

      while (my ($key, $val) = splice @match, 0, 2)
      {
         next unless $val;
         $val = GREEN.$val.RESET if $key eq 'match';
         push @info, $GRAY.$key.RESET.": $val";
      }

      my $info = join ', ', @info;
      say $pre.GREEN.$match.RESET.$post, " ($info)";
      say ' ' x length($pre) . '^' x length($match) . ' ' x length($post);
   }
   else {
      warn RED.'no match'.RESET, "\n";
   }
}
