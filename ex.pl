#! /usr/bin/env perl

# Fuzzy files explorer

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;
use Term::ANSIColor qw/color :constants/;
use File::Basename 'fileparse';

# Help
sub help()
{
   print << 'MSG';
ex [options] [topic]

--(no-)hidden,   -H: include hidden files (default)
--directory=dir, -d: change root directory
--exact,         -e: exact filename matches
--grep,          -g: grep for occurrences of topic in files
--only,          -o: output filetred lines only
--view,          -v: view with your $EDITOR, use Alt-v from within fzf
MSG
   exit;
}

# Arguments
my $dir = '.';
my $hidden = 1;

my ($exact, $grep, $only, $view);
GetOptions (
   'H|hidden!'     => \$hidden,
   'd|directory=s' => \$dir,
   'e|exact'       => \$exact,
   'g|grep'        => \$grep,
   'o|only'        => \$only,
   'v|view'        => \$view,
   'h|help'        => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

$dir = glob $dir if $dir =~ /^~/;
$dir =~ s'/+$'';

chdir $dir or die RED.$!.RESET, "\n";

$hidden = $hidden ? '--hidden' : '';

# Globals
my ($query, $key, $file);

# Functions
sub fzf_results()
{
   my @output = split /\n/;
   exit 1 unless @output; # canceled with Esc or ^C

   if ($output[0] and @output < 3) # only if no results
   {
      $query = $output[0];
      $query =~ tr/^$\'//d; # partial support of fzf's extended search mode
   }
   $key = $output[1];

   if (@output == 3) # query / key pressed / file
   {
      $file = $output[-1];
      return 1;
   }
   return undef;
}

sub Open(;$)
{
   exit 1 unless $file;
   my $open = $^O eq 'darwin' ? 'open' : 'xdg-open';

   my (undef, undef, $ext) = fileparse($file, qr/\.[^.]+$/);

   # open with your EDITOR
   if ($key or $view)
   {
      # open with nvim (send to running instance)?
      if (@_ and $ENV{EDITOR} =~ /vim/i)
      {
         exec $ENV{EDITOR}, $file, '-c', "0/$query", '-c', 'noh|norm zz<cr>';
      } else {
         exec $ENV{EDITOR}, $file;
      }
   }

   # open with adequate app
   # binary files, is -x test needed?
   if (not -x $file and -B _ || $ext =~ /\.pdf$/i)
   {
      exec $open, $file;
   }

   # grep only
   exec qw/rg -S/, $query, $file if $only;

   # personal help files
   if (-f "$ENV{REPOS_BASE}/help/$file")
   {
      if ($ext =~ /\.md$/i)
      {
         # open markdown docs in the browser
         exec $open, "https://github.com/kurkale6ka/help/blob/master/$file";
      }
      elsif ($file eq 'printf.pl')
      {
         say CYAN, $dir ne '.' ? "$dir/":'', $file, RESET;
         do "./$file";
         exit;
      }
   }

   # display path of file being viewed
   say CYAN, $dir ne '.' ? "$dir/":'', $file, RESET;

   # cat
   if ($ext =~ /\.(?!te?xt).+$/i)
   {
      exec qw/bat --style snip --italic-text always --theme zenburn -mconf:ini/, $file;
   } else {
      exec 'cat', $file;
   }
}

my $find = "fd -tf $hidden -E.git -E.svn -E.hg --ignore-file ~/.gitignore";
my $fzf_opts = '-0 -1 --cycle --print-query --expect=alt-v';
my $preview = q/--preview 'if file --mime {} | grep -q binary; then echo "No preview available" 1>&2; else cat {}; fi'/;

sub Grep()
{
   my $results = 0;
   until ($results)
   {
      exit 1 unless $query;
      chomp ($_ = `rg -S $hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l $query | fzf $fzf_opts --preview 'rg -S --color=always $query {}'`);
      $results = fzf_results;
   }

   Open '--hls' if $results;
   exit;
}

# Main
# Search help files matching topic
if (@ARGV)
{
   # multiple args, split @ARGV with -e?
   # rg -Sl patt1 | ... | xargs rg -S pattn
   # also for fd ... $1
   $query = shift;

   Grep if $grep; # force searching for files with occurrences of topic

   # fd without query matches anything, thus fzf will filter on whole paths,
   # this is why with query (--exact), -p is needed so query can filter on whole paths too
   my $mode = defined $exact ? "-pF $query" : '';

   # -q isn't required with 'exact', it's supplied to enable highlighting
   chomp ($_ = `$find $mode | fzf -q$query $fzf_opts $preview`);

}
# Search trough all help files
else
{
   # fuzzy (default) or exact?
   my $mode = defined $exact ? '-e' : '';
   chomp ($_ = `$find | fzf $mode $fzf_opts $preview`);
}

if (fzf_results)
{
   Open;
} else {
   # if no matching filenames were found, list files with occurrences of topic
   Grep;
}
