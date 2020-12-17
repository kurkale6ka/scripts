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
use File::Basename 'fileparse';

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

sub fzf_results
{
   my @output = split '\n';
   exit 1 unless @output; # canceled with Esc or ^C

   $query = $output[0] if $output[0];
   $key = $output[1];

   if (@output == 3) # query / key pressed / file
   {
      $file = $output[-1];
      return 1;
   }
}

# simply Open (no $_)?
sub Open
{
   exit 1 unless $file;

   my (undef, undef, $ext) = fileparse($file, qr/\.[^.]+$/);

   # say caller;
   if ($key or $view)
   {
      # open with nvim (send to running instance)?
      if (@_ and $ENV{EDITOR} =~ /vim/i)
      {
         # before 'modelineexpr, zv was used
         exec $ENV{EDITOR}, $file, '-c', "0/$query", '-c', 'noh|norm zz<cr>';
      } else {
         exec $ENV{EDITOR}, $file;
      }
   }

   # binary files
   if ($ext =~ /\.pdf$/i or -B $file and not -x _)
   {
      # prompt for yes/no?
      exec 'open', $file;
   }

   # personal help files
   if (-f "$ENV{REPOS_BASE}/help/$file")
   {
      if ($ext =~ /\.md$/i)
      {
         exec 'open', "https://github.com/kurkale6ka/help/blob/master/$file";
      }
      elsif ($ext =~ /\.pl$/i)
      {
         say CYAN."$dir/$file".RESET;
         do "./$file";
         exit;
      }
   }

   # display path of file being viewed
   say CYAN."$dir/$file".RESET;

   if ($ext =~ /\.(?!te?xt).+$/i)
   {
      exec qw/bat --style snip --italic-text always --theme zenburn -mconf:ini/, $file;
   } else {
      exec 'cat', $file;
   }
}

sub Grep($)
{
   $query = shift;

   my $results = 0;
   until ($results)
   {
      exit 1 unless $query;
      $_ = `rg -S --hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l $query | fzf -0 -1 --cycle --print-query --expect='alt-v' --preview "rg -Sn --color=always $query {}"`;
      chomp;
      $results = fzf_results;
   }

   Open '--hls' if $results;
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
   chomp ($_ = `$find $mode | fzf -q'@ARGV' $fzf_opts`);

} else {
   # Search trough all help files
   my $mode = defined $exact ? '-e' : '';

   chomp ($_ = `$find | fzf $mode $fzf_opts`);
}

if (fzf_results)
{
   Open;
} else {
   # if no matching filenames were found, list files with occurrences of topic
   # when canceling with ctrl+c we don't want any further searches, this is why a simple Grep unless $_ isn't enough
   Grep $query;
}
