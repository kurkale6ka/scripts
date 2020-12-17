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

chdir ($dir = glob $dir ||= '.') or die RED.$!.RESET, "\n";

my ($query, $key, $file);
my $results = 0;

sub fzf_results
{
   ($query, $key, $file) = split '\n';
   $_ //= '' foreach $query, $key, $file;

   exit 130 if $query =~ /^130$/; # canceled with Esc or ^C
   $results = 1 unless $file =~ /^1$/;
}

# simply Open (no $_)?
sub Open
{
   exit 1 unless $file;

   # say caller;
   if ($key or $view)
   {
      exec $ENV{EDITOR}, $file;
   }

   exec 'cat', $file;
}

sub Grep($)
{
   $query = shift;

   until ($results)
   {
      exit 1 unless $query;
      $_ = `rg -S --hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l $query | fzf -0 -1 --cycle --print-query --expect='alt-v' --preview "rg -Sn --color=always $query {}" || echo \${PIPESTATUS[1]}`;
      chomp;
      fzf_results;
   }

   Open $_ if $results;
   exit;
}

# check --read0
my $find = 'fd -tf -H -E.git -E.svn -E.hg --ignore-file ~/.gitignore -0';
my $fzf_opts = q(--read0 -0 -1 --cycle --print-query --expect='alt-v' --preview 'if file --mime {} | grep -q binary; then echo "No preview available" 1>&2; else cat {}; fi');

if (@ARGV)
{
   Grep "@ARGV" if $grep;

   # Search help files matching topic
   # find without arg prints whole paths that we later match with fzf
   # this is why we need -p arg so we get the same behaviour
   my $mode = defined $exact ? "-p @ARGV" : '';

   # -q isn't required with 'exact', it's supplied to enable highlighting
   chomp ($_ = `$find $mode | fzf -q'@ARGV' $fzf_opts || echo \${PIPESTATUS[1]}`);
   fzf_results;

} else {
   # Search trough all help files
   my $mode = defined $exact ? '-e' : '';

   chomp ($_ = `$find | fzf $mode $fzf_opts || echo \${PIPESTATUS[1]}`);
   fzf_results;
}

if ($results)
{
   Open $_;
} else {
   # if no matching filenames were found, list files with occurrences of topic
   # when canceling with ctrl+c we don't want any further searches, this is why a simple Grep unless $_ isn't enough
   Grep $query;
}
