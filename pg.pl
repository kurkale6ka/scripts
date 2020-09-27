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

my $custom_fields = 1;
my ($long, $help, @extra);
GetOptions (
   'c|custom-fields!' => \$custom_fields,
   'l|long'           => \$long,
   'z|squeeze!'       => \$squeeze,
   'h|help'           => \$help,
   '<>'               => \&extra_options,
) or die RED.'Error in command line arguments'.RESET, "\n";

my $selinux;
my $pattern;

sub extra_options {
   foreach (@_) {
      if (/^-/) {
         unless ($_ eq '-Z')
         {
            push @extra, $_;
         } else {
            $selinux = 1;
         }
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
pg [options] pattern

--(no-)custom-fields, -c: PID STAT EUSER EGROUP START CMD
--long,               -l: PID PPID PGID SID TTY TPGID STAT EUSER EGROUP START CMD
--(no-)squeeze,       -z: squeeze! no context lines
MSG

   if ($custom_fields)
   {
      unless ($long)
      {
         @fields = qw/pid stat euser egroup start_time cmd/;
      } else {
         @fields = qw/pid ppid pgid sid tname tpgid stat euser egroup start_time cmd/;
      }
      unshift @fields, 'label' if $selinux;

      @ps = (qw/ps faxww/, @extra, 'o', join ',', @fields);
   } else {
      @ps = (qw/ps faxww/, @extra);
   }

} elsif ($^O eq 'darwin') {

   $usage = << 'MSG';
pg [options] pattern

--(no-)custom-fields, -c: PID STAT USER GID STARTED COMMAND
--long,               -l: PID PPID PGID SESS TTY TPGID STAT USER GID STARTED COMMAND
--(no-)squeeze,       -z: squeeze! no context lines (default)
MSG

   if ($custom_fields)
   {
      unless ($long)
      {
         @fields = qw/pid stat user group start command/;
      } else {
         @fields = qw/pid ppid pgid sess tty tpgid stat user group start command/;
      }

      @ps = (qw/ps axww/, @extra, '-o', join ',', @fields);
   } else {
      @ps = (qw/ps axww/, @extra);
   }
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
      # add color
      s/($search)/${RED}${S}$1${R}/g;
      push @matches, [$., $_];
   }
}

# no matches
exit 1 unless @matches;

my $prev_num;

say BOLD.$header.RESET;

foreach (@matches)
{
   my ($num, $match) = @$_;

   # group results, 'grep -C' style
   unless ($squeeze)
   {
      if ($prev_num)
      {
         say CYAN.'--'.RESET if ++$prev_num < $num;
      }
      $prev_num = $num;
   }

   say $match;
}
