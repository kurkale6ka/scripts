#! /usr/bin/env perl

# head all text files, excluding backups~

use strict;
use warnings;
use re '/aa';
use feature 'say';
use feature 'state';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;

# Help
my $help = << 'MSG';
headall [options] [pattern]
-n, --lines=NUM : print the first NUM lines
-v, --view      : view folds in vim
MSG

# Options
my $lines = 10;
my ($view, $PIPE);
GetOptions (
   'n|lines=i' => \$lines,
   'v|view'    => \$view,
   'h|help'    => sub { print $help; exit; }
) or die RED.'Error in command line arguments'.RESET, "\n";

die RED.'NUM > 0 expected'.RESET, "\n" unless $lines > 0;
die $help unless @ARGV <= 1;

if ($view)
{
   # die unless edit vim
   open $PIPE, '|-', $ENV{EDITOR}, '-c', "se fdl=0 fdm=expr fde=getline(v:lnum)=~'==>'?'>1':'='", '-' or die RED.$!.RESET, "\n";
   select $PIPE;
}

sub file (_)
{
   my @delimiters = qw/==> <==/;
   unless ($view)
   {
      my $GRAY = color('ansi242');
      @delimiters = map {$GRAY.$_.RESET} @delimiters;
   }
   join " $_[0] ", @delimiters;
}

my $pattern = quotemeta shift if @ARGV;
my @empty;

opendir my $DIR, '.' or die RED.$!.RESET, "\n";
FILE: while (readdir $DIR)
{
   # tests
   if ($pattern)
   {
      next unless /$pattern/i;
   }
   next unless -f -T; # text
   next if /~$/;
   if (-z _)
   {
      push @empty, $_; next;
   }

   # output
   print "\n" if state $line++;
   say file;

   open my $FH, '<', $_ or die RED.$!.RESET, "\n";
   while (<$FH>)
   {
      chomp;
      next FILE if $. == $lines+1;
      say;
   }
}

print "\n" if @empty;
say file.' : empty' foreach @empty;
