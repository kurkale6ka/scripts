#! /usr/bin/env perl

# Fuzzy files explorer

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
ex [options] [topic]

--hidden,        -H: include hidden files
--directory=dir, -d: change root directory
--exact,         -e: exact filename matches
--grep,          -g: grep for occurrences of topic in files
--only,          -o: output filetred lines only
--view,          -v: view with your $EDITOR, use alt-v from within fzf
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

chdir glob $dir ||= '.' or die RED.$!.RESET, "\n";
$dir =~ s(/+$)();

my ($query, $key, $file);

sub fzf_results()
{
   my @output = split '\n';
   exit 1 unless @output; # canceled with Esc or ^C

   $query = $output[0] if $output[0] and @output < 3;
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

   # binary files, is -x test needed?
   if ($ext =~ /\.pdf$/i or -B $file and not -x _)
   {
      # prompt for yes/no?
      exec $open, $file;
   }

   # grep only
   exec qw/rg -S/, $query, $file if $only;

   # personal help files
   if (-f "$ENV{REPOS_BASE}/help/$file")
   {
      if ($ext =~ /\.md$/i)
      {
         exec $open, "https://github.com/kurkale6ka/help/blob/master/$file";
      }
      elsif ($ext =~ /\.pl$/i)
      {
         say CYAN, $dir ne '.' ? "$dir/":'', $file, RESET;
         do "./$file";
         exit;
      }
   }

   # display path of file being viewed
   say CYAN, $dir ne '.' ? "$dir/":'', $file, RESET;

   if ($ext =~ /\.(?!te?xt).+$/i)
   {
      exec qw/bat --style snip --italic-text always --theme zenburn -mconf:ini/, $file;
   } else {
      exec 'cat', $file;
   }
}

my $find = 'fd -tf -H -E.git -E.svn -E.hg --ignore-file ~/.gitignore';
my $fzf_opts = '-0 -1 --cycle --print-query --expect=alt-v';

sub Grep($)
{
   $query = shift;

   my $results = 0;
   until ($results)
   {
      exit 1 unless $query;
      chomp ($_ = `rg -S --hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l $query | fzf $fzf_opts --preview 'rg -S --color=always $query {}'`);
      $results = fzf_results;
   }

   Open '--hls' if $results;
   exit;
}

if (@ARGV)
{
   # multiple args, split -e?
   Grep "@ARGV" if $grep;

   # Search help files matching topic
   # find without arg prints whole paths that we later match with fzf
   # this is why we need -p arg so we get the same behaviour
   # -F?
   my $mode = defined $exact ? '-p' : '';

   # -q isn't required with 'exact', it's supplied to enable highlighting
   chomp ($_ = `$find $mode '@ARGV' | fzf -q'@ARGV' $fzf_opts`);

} else {
   # Search trough all help files
   my $mode = defined $exact ? '-e' : '';

   chomp ($_ = `$find | fzf $mode $fzf_opts --preview 'if file --mime {} | grep -q binary; then echo "No preview available" 1>&2; else cat {}; fi'`);
}

if (fzf_results)
{
   Open;
} else {
   # if no matching filenames were found, list files with occurrences of topic
   Grep $query;
}
