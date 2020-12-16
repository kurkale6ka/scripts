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
use File::Glob ':bsd_glob';

# Help
sub help()
{
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
my ($hidden, $dir, $exact, $grep, $only, $view);
GetOptions (
   'H|hidden'      => \$hidden,
   'd|directory=s' => \$dir,
   'e|exact'       => \$exact,
   'g|grep'        => \$grep,
   'o|only'        => \$only,
   'v|view'        => \$view,
   'h|help'        => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

$dir = glob $dir ||= '.';

sub Open
{
   # say caller;
   my ($key, $file) = split '\n', shift;

   if ($key or $view)
   {
      exec $ENV{EDITOR}, $file;
   }

   exec 'cat', $file;
}

sub Grep
{
   chdir $dir or die RED.$!.RESET, "\n";

   $_ = `rg -S --hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l @ARGV | fzf -0 -1 --cycle --expect='alt-v' --preview "rg -Sn --color=always @ARGV $dir/{}"`;
   chomp;

   Open $_ if $_;
}

if (@ARGV)
{
   if ($grep)
   {
      Grep();
   } else {
      # fuzzy
      chdir $dir or die RED.$!.RESET, "\n";

      $_ = `fd -tf -H -E.git -E.svn -E.hg --ignore-file ~/.gitignore -0 | fzf -q"@ARGV" --read0 -0 -1 --cycle --expect='alt-v' --preview 'if file --mime {} | grep -q binary; then echo "No preview available" 1>&2; else cat {}; fi' || echo \${PIPESTATUS[1]}`;
      chomp;

      if (/^\n1$/) # no results
      {
         Grep @ARGV;
      } elsif (!/^130$/) { # canceled with ctrl+c
         Open $_;
      }
   }
} else {
}
