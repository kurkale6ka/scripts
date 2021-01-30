#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $GRAY = color('ansi242');

my $help = << 'MSG';
rr str /reg/
rr str
rr /reg/
MSG

# Arguments
GetOptions (
   'h|help' => sub {print $help; exit}
) or die RED.'Error in command line arguments'.RESET, "\n";

die $help unless @ARGV;

my ($str, $reg);

my $regex_arg = qr! ^/(.*?)/(.*) !x;

if (@ARGV == 2)
{
   ($str, $reg) = @ARGV;
   $reg = eval "qr/$1/$2" if $reg =~ $regex_arg;
   match();
}
elsif (@ARGV == 1)
{
   # rr /reg/
   if ($ARGV[0] =~ $regex_arg)
   {
      # get flags
      $reg = eval "qr/$1/$2";
      repl('regex');
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

   my $prompt = CYAN . (@_ ? '$$ ' : '// ') . RESET;

   while (defined ($_ = $term->readline($prompt)))
   {
      if (@_) # rr /reg/
      {
         chomp ($str = $_);
      } else {
         chomp ($reg = $_);
      }
      match();
   }
}

sub match
{
   return unless $str and $reg;
   if ($str =~ $reg)
   {
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
   } else {
      say RED.'no match'.RESET;
   }
}
