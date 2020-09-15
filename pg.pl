#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $BLUE = color('ansi69');
my $CYAN = color('ansi45');
my $RED = color('red');
my $S = color('bold');
my $R = color('reset');

my $usage;
my @fields;

unless ($^O eq 'darwin')
{
   $usage = << 'MSG';
pg [-lz] pattern
  -l: PID PPID PGID SID TTY TPGID STAT EUSER EGROUP START CMD
  -z: squeeze! no context lines.
MSG

@fields = qw/pid stat euser egroup start_time cmd/;
}
else
{
   $usage = << 'MSG';
pg [-l] pattern
    -l: PID PPID PGID SESS TTY TPGID STAT USER GID STARTED COMMAND
MSG

@fields = qw/pid stat user group start command/;
}

# Help
sub help() {
   print $usage;
   exit;
}

my $long;

# Arguments
GetOptions (
   'l|long' => \$long,
   'h|help' => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# @fields = qw/pid ppid pgid sid tname tpgid stat euser egroup start_time cmd/
@fields = qw/pid ppid pgid sess tty tpgid stat user group start command/
if $long;

my $search = qr/\Q$ARGV[0]\E/i;

my @ps = $^O ne 'darwin' ? qw/ps faxww o/ : qw/ps axww -o/;

open my $fh, '-|', @ps, join ',', @fields
   or die RED."$!".RESET, "\n";

while (<$fh>)
{
   chomp;
   if (1..1) { say; next; } # ps header
   if (/$search/)
   {
      s/$search/$RED$&$R/g;
      say;
   }
}
