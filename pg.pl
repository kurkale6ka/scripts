#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $RED = color('red');
my $S = color('bold');
my $R = color('reset');

# Arguments
my @extra = grep {/^--?[^lzh-]/} @ARGV;

my ($long, $squeeze, $help);
GetOptions (
   'l|long'    => \$long,
   'z|squeeze' => \$squeeze,
   'h|help'    => \$help,
) or die RED.'Error in command line arguments'.RESET, "\n";

my ($usage, @ps, @fields);

if ($^O eq 'linux')
{
   $usage = << 'MSG';
pg [-lz] pattern
  -l: PID PPID PGID SID TTY TPGID STAT EUSER EGROUP START CMD
  -z: squeeze! no context lines.
MSG

   @ps = qw/ps faxww o/;

   unless ($long)
   {
      @fields = qw/pid stat euser egroup start_time cmd/;
   } else {
      @fields = qw/pid ppid pgid sid tname tpgid stat euser egroup start_time cmd/;
   }

} elsif ($^O eq 'darwin') {

   $usage = << 'MSG';
pg [-l] pattern
    -l: PID PPID PGID SESS TTY TPGID STAT USER GID STARTED COMMAND
MSG

   @ps = qw/ps axww -o/;

   unless ($long)
   {
      @fields = qw/pid stat user group start command/;
   } else {
      @fields = qw/pid ppid pgid sess tty tpgid stat user group start command/;
   }
}

# Help
sub help() {
   print $usage;
   exit;
}

help if $help or @ARGV == 0;

my (@prev_line, @matches);

my $self = qr/\Q$0\E\b/;
my $search = qr/\Q$ARGV[0]\E/i; # make Smart case

open my $PS, '-|', @ps, @extra, join ',', @fields
   or die RED."$!".RESET, "\n";

chomp (my $header = <$PS>);

while (<$PS>)
{
   chomp;
   unless (/$search/)
   {
      @prev_line = ($., $_);
   } else {
      next if /$self/;
      if (@prev_line)
      {
         push @matches, [@prev_line] unless $squeeze;
         @prev_line = ();
      }
      s/($search)/${RED}${S}$1${R}/g;
      push @matches, [$., $_];
   }
}

exit 1 unless @matches;

my $prev_num;

say BOLD.$header.RESET;

foreach (@matches)
{
   my ($num, $match) = $_->@*;
   if ($prev_num and not $squeeze)
   {
      say CYAN.'--'.RESET if ++$prev_num < $num;
   }
   say $match;
   $prev_num = $num;
}
