#! /usr/bin/env perl

# Fuzzy files explorer
#
# Usage: ex [-d{dir}] [-e] [-g] [-v] [topic]

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;
use Term::ANSIColor qw/color :constants/;

# Help
sub help() {
   print << 'MSG';
ex [-H] [-d{dir}] [-e] [-g] [-v] [topic]

 -H: include hidden files
 -d: change root directory
 -e: exact filename matches
 -g: grep for occurrences of topic in files
 -v: view with your $EDITOR, use alt-v from within fzf
MSG
   exit;
}

# Arguments
my $dir = '.';
my ($hidden, $exact, $grep, $view);
GetOptions (
   'H|hidden'      => \$hidden,
   'd|directory=s' => \$dir,
   'e|exact'       => \$exact,
   'g|grep'        => \&occurrences,
   'v|view'        => \$view,
   'h|help'        => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

sub occurrences
{
   chdir $dir or die RED.$!.RESET, "\n";

   my @files = `rg -S --hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l @ARGV | fzf -0 -1 --cycle --expect='alt-v' --preview "rg -Sn --color=always @ARGV $dir/{}"`;
   chomp @files;

   say for @files;
   # exec 'cat', @files;
}
