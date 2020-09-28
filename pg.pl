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

# Arguments
my $custom_fields = 1;
my $squeeze = 1 if $^O eq 'darwin';
my ($long, $help, @extra_options);

GetOptions (
   'c|custom-fields!' => \$custom_fields,
   'l|long'           => \$long,
   'z|squeeze!'       => \$squeeze,
   'h|help'           => \$help,
   '<>'               => \&extra,
) or die RED.'Error in command line arguments'.RESET, "\n";

my ($selinux, $pattern);

sub extra {
   foreach (@_) {
      if (/^-/) {
         unless ($_ eq '-Z')
         {
            push @extra_options, $_;
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

ps options can be passed through
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

      push @ps, qw/ps faxww/, @extra_options, 'o', join ',', @fields;
   } else {
      push @ps, qw/ps faxww/, @extra_options;
   }

} elsif ($^O eq 'darwin') {

   $usage = << 'MSG';
pg [options] pattern

--(no-)custom-fields, -c: PID STAT USER GID STARTED COMMAND
--long,               -l: PID PPID PGID SESS TTY TPGID STAT USER GID STARTED COMMAND
--(no-)squeeze,       -z: squeeze! no context lines (default)

ps options can be passed through
MSG

   if ($custom_fields)
   {
      unless ($long)
      {
         @fields = qw/pid stat user group start command/;
      } else {
         @fields = qw/pid ppid pgid sess tty tpgid stat user group start command/;
      }

      push @ps, qw/ps axww/, @extra_options, '-o', join ',', @fields;
   } else {
      push @ps, qw/ps axww/, @extra_options;
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
      s/($search)/BOLD.RED.$1.RESET/eg if -t STDOUT;
      push @matches, [$., $_];
   }
}

# no matches
exit 1 unless @matches;

my $prev_num;

say $header;
say '-' x length $header;

foreach (@matches)
{
   my ($num, $match) = @$_;

   # group results, 'grep -B1' style
   unless ($squeeze)
   {
      if ($prev_num and ++$prev_num < $num)
      {
         say -t STDOUT ? CYAN.'--'.RESET : '--';
      }
      $prev_num = $num;
   }

   say $match;
}
