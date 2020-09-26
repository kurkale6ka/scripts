#! /usr/bin/env perl

# Human readable pgrep
#
# - ps options can be passed along
# - Smart case
# - context lines (like grep's -B1)

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling pass_through/;

my $RED = color('red');
my $S = color('bold');
my $R = color('reset');

# Arguments
my $squeeze = 1 if $^O eq 'darwin';

my ($long, $help, @extra);
GetOptions (
   'l|long'     => \$long,
   'z|squeeze!' => \$squeeze,
   'h|help'     => \$help,
   '<>'         => \&extra_options,
) or die RED.'Error in command line arguments'.RESET, "\n";

my $pattern;

sub extra_options {
   foreach (@_) {
      if (/^-/) {
         push @extra, $_;
      } else {
         # FIXME: many patterns?
         $pattern = $_;
      }
   }
}

my ($usage, @fields, @ps);

if ($^O eq 'linux')
{
   $usage = << 'MSG';
pg [-lz] pattern

--long,         -l: PID PPID PGID SID TTY TPGID STAT EUSER EGROUP START CMD
--(no-)squeeze, -z: squeeze! no context lines
MSG

   unless ($long)
   {
      @fields = qw/pid stat euser egroup start_time cmd/;
   } else {
      @fields = qw/pid ppid pgid sid tname tpgid stat euser egroup start_time cmd/;
   }

   @ps = (qw/ps faxww/, @extra, 'o', join ',', @fields);

} elsif ($^O eq 'darwin') {

   $usage = << 'MSG';
pg [-lz] pattern

--long,         -l: PID PPID PGID SESS TTY TPGID STAT USER GID STARTED COMMAND
--(no-)squeeze, -z: squeeze! no context lines (default)
MSG

   unless ($long)
   {
      @fields = qw/pid stat user group start command/;
   } else {
      @fields = qw/pid ppid pgid sess tty tpgid stat user group start command/;
   }

   @ps = (qw/ps axww/, @extra, '-o', join ',', @fields);
}

# Help
sub help() {
   print $usage;
   exit;
}

help() if $help or not $pattern;

my $search;
my $self = qr/\Q$0\E\b/;

my (@prev_line, @matches);

# Smart case
unless ($pattern =~ /[A-Z]/)
{
   $search = qr/\Q$pattern\E/i;
} else {
   $search = qr/\Q$pattern\E/;
}

open my $PS, '-|', @ps or die RED.$!.RESET, "\n";

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
   $prev_num = $num;

   say $match;
}
