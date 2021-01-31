#! /usr/bin/env perl

# Perl regex REPL
#
# Alternatively:
#   use re 'debug';
#   use diagnostics;
#   or use the debugger :-)
#
# todo: sanitize input (chroot, ..., or warn) + fix newlines (/regex/s)

use strict;
use warnings;
use feature 'say';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $GRAY = color('ansi242');

my $help = << 'MSG';
rr regex[/flags]
rr scalar
rr scalar regex
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
   $str =~ $reg or die RED.'no match'.RESET, "\n";

   my @info;
   my @match = (pre => $`, match => $&, post => $');

   while (my ($key, $val) = splice @match, 0, 2)
   {
      next unless $val;
      $val = GREEN.$val.RESET if $key eq 'match';
      push @info, $GRAY.$key.RESET.": $val";
   }

   my $info = join ', ', @info;
   say $`. GREEN.$&.RESET . $', " ($info)";
   say ' ' x length($`) . '^' x length($&) . ' ' x length($');
}
