#! /usr/bin/env perl

# 'head' all text files, excluding backups~
#
# todo: exclude stuff from .gitignore

use v5.12;
use warnings;
use re '/aa';
use Getopt::Long qw/GetOptions :config bundling/;
use Term::ANSIColor qw/color :constants/;

# Help
my $help = << '';
headall [pattern]
-n, --lines=NUM : print the first NUM lines, 10 default
-v, --view      : view with folds in (n)vim, :h folds

# Options
my $lines = 10;
GetOptions (
   'n|lines=i' => \$lines,
   'v|view'    => \my $view,
   'h|help'    => sub { print $help; exit; }
) or die RED.'Error in command line arguments'.RESET, "\n";

die RED.'NUM > 0 expected'.RESET, "\n" if $lines < 1;
die $help if @ARGV > 1;

# View in (n)vim
if ($view)
{
   die RED.'EDITOR must be (n)vim'.RESET, "\n" unless $ENV{EDITOR} =~ /vim/i;
   open my $PIPE, '|-', $ENV{EDITOR}, '-c', "setl bt=nofile bh=hide noswf fdl=0 fdm=expr fde=getline(v:lnum)=~'==>'?'>1':'='", '-'
      or die RED.$!.RESET, "\n";
   select $PIPE;
}

# Format filename
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

# Main
my $pattern = quotemeta shift if @ARGV;
my @empty;

# iterate over files in the current directory
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
      push @empty, $_;
      next;
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

# empty files
print "\n" if @empty;
say file.' : empty' foreach @empty;
