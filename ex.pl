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
--view,          -v: view with your $EDITOR, use Alt-v from within fzf
────

my ($dir, $hidden) = ('.', 1);

# Options
GetOptions (
   'H|hidden!'     => \$hidden,
   'd|directory=s' => \$dir,
   'e|exact'       => \my $exact,
   'g|grep'        => \my $grep,
   'o|only'        => \my $only,
   'v|view'        => \my $view,
   'h|help'        => sub { print $help; exit }
) or die RED.'Error in command line arguments'.RESET, "\n";

$dir = glob $dir if $dir =~ /^~/;
$dir =~ s'/+$'';

chdir $dir or die RED.$!.RESET, "\n";

$hidden = $hidden ? '--hidden' : '';

# Globals
my ($query, $key, $file, @results);

# Functions
sub fzf_results
{
   exit 1 unless grep /\S/, @_; # canceled with Esc or ^C
   ($query, $key, $file) = @_;

   if ($file) {
      return 1;
   } else {
      # trim any fzf extended search mode characters
      $query =~ s/^'//;
      $query =~ tr/^\\$//d;

      $query =~ s/'/'"'"'/g; # protect 's
      return undef;
   }
}

sub Open
{
   my $open = $^O eq 'darwin' ? 'open' : 'xdg-open';

   my (undef, undef, $ext) = fileparse ($file, qr/\.[^.]+$/);

   # open with your EDITOR
   if ($key or $view)
   {
      my $EDITOR = $ENV{EDITOR} || 'vi';

      # open with nvim (send to running instance)?
      if (@_ and $EDITOR =~ /vim/i)
      {
         exec $EDITOR, $file, '-c', "0/$query", '-c', 'noh|norm zz<cr>';
      } else {
         exec $EDITOR, $file;
      }
   }

   # open with adequate app
   # binary files, is -x test needed?
   if (not -x $file and -B _ || $ext =~ /\.pdf$/i)
   {
      exec $open, $file;
   }

   # grep only
   exec qw/rg -FS/, $query, $file if $only;

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

sub Grep
{
   while (1)
   {
      my $preview = "rg -FS --color=always '$query' {}";
      $preview =~ s/[\\"`\$]/\\$&/g; # quote sh ""s special characters (\ " ` $)
      @results = `rg -FS $hidden -g'!.git' -g'!.svn' -g'!.hg' --ignore-file ~/.gitignore -l '$query' | fzf $fzf_opts --preview "$preview"`;
      chomp @results;
      Open '--hls' if fzf_results @results;
   }
}

# Main
# Search help files matching topic
if (@ARGV)
{
   # multiple args, split @ARGV with -e?
   # rg -Sl patt1 | ... | xargs rg -S pattn
   # also for fd ... $1
   $query = shift;
   $query =~ s/'/'"'"'/g;

   Grep if $grep; # force searching for files with occurrences of topic

   # fd without query matches anything, thus fzf will filter on whole paths,
   # this is why with query (--exact), -p is needed so query can filter on whole paths too
   my $mode = defined $exact ? "-pF '$query'" : '';

   # -q isn't required with 'exact', it's supplied to enable highlighting
   chomp (@results = `$find $mode | fzf -q'$query' $fzf_opts $preview`);
}
# Search trough all help files
else
{
   # fuzzy (default) or exact?
   my $mode = defined $exact ? '-e' : '';
   chomp (@results = `$find | fzf $mode $fzf_opts $preview`);
}

# Match topic
if (fzf_results @results)
{
   Open
} else {
   # no matching filenames => list files with occurrences of topic
   Grep
}
