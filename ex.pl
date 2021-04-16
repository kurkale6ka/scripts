#! /usr/bin/env perl

# Fuzzy files explorer

use v5.12;
use warnings;
use utf8;
use re '/aa';
use Getopt::Long qw/GetOptions :config no_ignore_case bundling/;
use Term::ANSIColor qw/color :constants/;
use File::Basename 'fileparse';

# Help
my $help = << '────';
ex [options] [topic]

--(no-)hidden,   -H: include hidden files (default)
--directory=dir, -d: change root directory
--exact,         -e: exact filename matches
--grep,          -g: grep for occurrences of topic in files
--only,          -o: output filetred lines only
--view,          -v: view with your $EDITOR, use alt-Enter from within fzf
────

my ($dir, $hidden) = ('.', 1);

# Options
GetOptions (
   'H|hidden!'     => \   $hidden,
   'd|directory=s' => \   $dir,
   'e|exact'       => \my $exact,
   'g|grep:s'      => \my $grep,
   'o|only'        => \my $only,
   'v|view'        => \my $view,
   'h|help'        => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

$dir = glob $dir if $dir =~ /^~/;
$dir =~ s'/+$'';

chdir $dir or die RED.$!.RESET, "\n";

$hidden = $hidden ? '--hidden' : '';

# Functions
sub fzf
{
   my ($query, $grep) = @_;

   $query =~ s/'/'"'"'/g if defined $query; # 'escape' 's

   my $fzf_opts = '-0 -1 --cycle --print-query --expect=alt-enter';
   my @results;

   if (defined $grep and (length $grep or length $query))
   {
      my $pattern;

      if (length $grep) {
         $pattern = $grep;
      } elsif (length $query) {
         $pattern = $query;
      }

      my $find = "rg -FS $hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l '$pattern'";
      my $preview = "rg -FS --color=always '$pattern' {}";

      $preview =~ s/[\\"`\$]/\\$&/g; # quote sh ""s special characters: \ " ` $

      my ($mode, $patt) = ('', '');

      if (length $query and length $grep)
      {
         $patt = "-q'$query'";
         $mode = '-e' if defined $exact;
      }

      @results = `$find | fzf $mode $patt $fzf_opts --preview "$preview"`;
   }
   else
   {
      my $find = "fd -tf $hidden -E.git -E.svn -E.hg --ignore-file ~/.gitignore";
      my $preview = "if file --mime {} | grep -q binary; then echo 'No preview available' 1>&2; else cat {}; fi";

      # search help files matching topic
      if (length $query)
      {
         # fd without query matches anything, thus fzf will filter on whole paths,
         # this is why with query (--exact), -p is needed so query can filter on whole paths too
         my $mode = defined $exact ? "-pF '$query'" : '';

         # -q isn't required with 'exact', it's supplied to enable highlighting
         @results = `$find $mode | fzf -q'$query' $fzf_opts --preview "$preview"`;
      }
      # search trough all help files
      else
      {
         # fuzzy (default) or exact?
         my $mode = defined $exact ? '-e' : '';

         @results = `$find | fzf $mode $fzf_opts --preview "$preview"`;
      }
   }

   chomp @results;
   exit 1 unless grep /\S/, @results; # canceled with Esc or ^C

   $query = $results[0];
   my (undef, $key, $file) = @results;

   # no results: trim any fzf extended search mode characters
   unless ($file)
   {
      $query =~ s/^'//;
      $query =~ tr/^\\$//d;
   }

   return ($query, $key, $file);
}

sub Open
{
   my ($query, $key, $file) = @_;

   # open with your EDITOR
   if ($key or $view)
   {
      my $EDITOR = $ENV{EDITOR} // 'vi';

      # open with nvim (send to running instance)?
      if ($grep and length $query and $EDITOR =~ /vim/i)
      {
         exec $EDITOR, $file, '-c', "0/$query", '-c', 'noh|norm zz<cr>';
      } else {
         exec $EDITOR, $file;
      }
   }

   my (undef, undef, $ext) = fileparse ($file, qr/\.[^.]+$/);

   my $open = $^O eq 'darwin' ? 'open' : 'xdg-open';

   # binary files, is -x test needed?
   if (not -x $file and -B _ || $ext =~ /\.pdf$/i)
   {
      exec $open, $file; # open with adequate app
   }

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
         say CYAN, ($dir ne '.' ? "$dir/" : ''), $file, RESET;
         do "./$file";
         exit;
      }
   }

   # display path of file being viewed
   say CYAN, ($dir ne '.' ? "$dir/" : ''), $file, RESET;

   # cat
   if ($ext =~ /\.(?!te?xt).+$/i)
   {
      exec qw/bat --style snip --italic-text always --theme zenburn -mconf:ini/, $file;
   } else {
      exec 'cat', $file;
   }
}

sub Grep
{
   my ($query, $grep) = @_;
   my ($query_bak, $key, $file);

   do {
      $query_bak = $query;
      ($query, $key, $file) = fzf $query, $grep;
   }
   until ($file);

   if ($only) # grep -o
   {
      exec qw/rg -FS/, $query_bak, $file;
   } else {
      Open $query_bak, $key, $file;
   }
}

# Main

# multiple args, split @ARGV with -e?
# rg -Sl patt1 | ... | xargs rg -S pattn
# also for fd ... $1
my $query = shift;
my $file;

# Search files matching topic

# grep -l | fzf
Grep ($query // '', $grep) if defined $grep;

# find | fzf
my @results = defined $query ? fzf $query : fzf;

($query, undef, $file) = @results;

# filename match
if ($file)
{
   Open @results;
} else {
   # list files with occurrences of topic
   Grep ($query, $grep // '');
}
