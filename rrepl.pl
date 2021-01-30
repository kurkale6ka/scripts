#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ReadLine;
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

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
   my $term = Term::ReadLine->new('Simple calculator');
   $term->ornaments(0);
   my $OUT = $term->OUT || \*STDOUT;

   while (defined ($_ = $term->readline (CYAN.'>>'.RESET.' ')))
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
      say ' ' x 3 . $`. GREEN.$&.RESET . $';
      # printf '%s%s%s%s', map {length} $prompt, $`, $&, $';
      say ' ' x 3 . ' ' x length($`) . '^' x length($&) . ' ' x length($');
   } else {
      say RED.'no match'.RESET;
   }
}

