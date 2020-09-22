#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $RED = color('red');
my $R = color('reset');

# Arguments
my ($long, $squeeze, $help, @extra);
GetOptions (
   'l|long'    => \$long,
   'z|squeeze' => \$squeeze,
   'h|help'    => \$help,
   # '*'         => \@extra,
) or die RED.'Error in command line arguments'.RESET, "\n";

say for @extra;

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

help if $help;

my $prev_line;
my $prog = qr/\Q$0\E/;
my $search = qr/\Q$ARGV[0]\E/i; # make smart

open my $fh, '-|', @ps, join ',', @fields
   or die RED."$!".RESET, "\n";

while (<$fh>)
{
   if (1..1) { print; next; } # ps header
   unless (/$search/)
   {
      $prev_line = $_ if $^O eq 'linux';
   } else {
      if ($prev_line)
      {
         print $prev_line unless $squeeze;
      }
      unless (/$prog/)
      {
         s/($search)/${RED}$1${R}/g;
         print;
      }
   }
}
