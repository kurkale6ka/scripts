#! /usr/bin/env perl

# Easier access to Perl help topics

use strict;
use warnings;
use feature 'say';
use re '/aa';
use Getopt::Long qw/GetOptions :config no_ignore_case pass_through/;
use Config;
use Module::CoreList;
use File::Spec;
use List::Util 'uniq';
use IPC::Open2;

sub dirname(_)
{
   ( File::Spec->splitpath($_[0]) )[1];
}

# Get man dirs plus associated pages extensions (man 3 Config)
# man1 => [man1dir, man1ext],
# man3 => [man3dir, man3ext],
my %man;
my $man_re = qr/(man\d)(dir|ext)/;

# config values (-Dman1dir=...) overwrite default values
foreach (Config::config_re($man_re), Config::config_re(qr/config_arg\d+/))
{
   next unless /$man_re/;
   my ($name, $type) = ($1, $2);
   unless (/config_arg\d+/)
   {
      $man{$name}[$type eq 'dir'? 0 : 1] = $Config{$&};
   } else {
      $man{$name}[$type eq 'dir'? 0 : 1] = (split /=/, $Config{$&})[1];
   }
}

my $MANPATH = join ':', uniq map {dirname @$_[0]} values %man;
my $MANSECT = join ':', uniq map {@$_[1]} values %man;

# Get info: try man, then perldoc
sub info
{
   my $topic = shift;
   unless (system ("man -M $MANPATH -S$MANSECT $topic 2>/dev/null") == 0)
   {
      exec 'perldoc', $topic;
   }
   exit;
}

# Usage
sub help
{
   print << 'MSG';
Easier access to Perl help topics

mp            : locate help sections
mp <section>  : (perl)re, (perl)run, ...
mp <function> : builtin function
mp $@%var     : variable, 2-chars variables can be invoked with v. (e.g v- for $-)
mp -v         : all variables
mp -m         : core module
mp -M         : core module code <= export PERLDOC_SRC_PAGER=$EDITOR
mp -          : file test operators

- fzf is needed for -v, -m, -M and <section/topic> lookup
  alt-enter will swap -m/-M actions
- extra options will be passed through to perldoc (ex: -q for FAQ search)
- mp aka 'man Perl' is an alias to this script
MSG
   exit;
}

# Options
GetOptions (
   'variables:s'     => \&variables,
   'm|module:s'      => \&module,
   'M|module-view:s' => \&module,
   'help'            => \&help,
   ''                => sub {exec qw/perldoc -f -/},
   '<>'              => \&extra
) or die "Error in command line arguments\n";

sub extra
{
   if ($_[0] =~ /^-/)
   {
      exec 'perldoc', @_, @ARGV;
   } else {
      unshift @ARGV, @_;
      die("!FINISH");
   }
}

sub module
{
   my ($opt, $val) = @_;

   my $modules = Module::CoreList::find_version $];
   my @modules = keys %$modules;

   unless ($val)
   {
      chomp ($_ = `printf '%s\n' @modules | fzf --expect='alt-enter' -0 -1 --cycle`);
   } else {
      chomp ($_ = `printf '%s\n' @modules | fzf -q'$val' --expect='alt-enter' -0 -1 --cycle`);
   }

   exit unless $_;
   my ($key, $page) = split /\n/;

   if (($opt eq 'm' and !$key) or ($opt eq 'M' and $key))
   {
      info $page;
   } else {
      exec qw/perldoc -m/, $page;
   }
}

sub variables
{
   my ($opt, $val) = @_;

   # perldoc -MPod::Simple::Text -T perlvar | egrep '^\s{4}[$@%]'
   my %vars =
   (
      '$_'                             => [qw/$ARG/],
      '@_'                             => [qw/@ARG/],
      '$"'                             => [qw/$LIST_SEPARATOR/],
      '$$'                             => [qw/$PID $PROCESS_ID/],
      '$0'                             => [qw/$PROGRAM_NAME/],
      '$('                             => [qw/$GID $REAL_GROUP_ID/],
      '$)'                             => [qw/$EGID $EFFECTIVE_GROUP_ID/],
      '$<'                             => [qw/$UID $REAL_USER_ID/],
      '$>'                             => [qw/$EUID $EFFECTIVE_USER_ID/],
      '$;'                             => [qw/$SUBSEP $SUBSCRIPT_SEPARATOR/],
      '$a'                             => [],
      '$b'                             => [],
      '%ENV'                           => [],
      '$]'                             => [qw/$OLD_PERL_VERSION/],
      '$^F'                            => [qw/$SYSTEM_FD_MAX/],
      '@F'                             => [],
      '@INC'                           => [],
      '%INC'                           => [],
      '$^I'                            => [qw/$INPLACE_EDIT/],
      '@ISA'                           => [],
      '$^M'                            => [],
      '$^O'                            => [qw/$OSNAME/],
      '%SIG'                           => [],
      '$^T'                            => [qw/$BASETIME/],
      '$^V'                            => [qw/$PERL_VERSION/],
      '${^WIN32_SLOPPY_STAT}'          => [],
      '$^X'                            => [qw/$EXECUTABLE_NAME/],
      '$<digits>'                      => [qw/$1 $2 .../],
      '@{^CAPTURE}'                    => [],
      '$&'                             => [qw/$MATCH/],
      '${^MATCH}'                      => [],
      '$`'                             => [qw/$PREMATCH/],
      '${^PREMATCH}'                   => [],
      '$\''                            => [qw/$POSTMATCH/],
      '${^POSTMATCH}'                  => [],
      '$+'                             => [qw/$LAST_PAREN_MATCH/],
      '$^N'                            => [qw/$LAST_SUBMATCH_RESULT/],
      '@+'                             => [qw/@LAST_MATCH_END/],
      '%+'                             => [qw/%LAST_PAREN_MATCH %{^CAPTURE}/],
      '@-'                             => [qw/@LAST_MATCH_START/],
      '%-'                             => [qw/%{^CAPTURE_ALL}/],
      '$^R'                            => [qw/$LAST_REGEXP_CODE_RESULT/],
      '${^RE_COMPILE_RECURSION_LIMIT}' => [],
      '${^RE_DEBUG_FLAGS}'             => [],
      '${^RE_TRIE_MAXBUF}'             => [],
      '$ARGV'                          => [],
      '@ARGV'                          => [],
      'ARGV'                           => [],
      'ARGVOUT'                        => [],
      '$,'                             => [qw/$OFS $OUTPUT_FIELD_SEPARATOR/],
      '$.'                             => [qw/$NR $INPUT_LINE_NUMBER/],
      '$/'                             => [qw/$RS $INPUT_RECORD_SEPARATOR/],
      '$\\'                            => [qw/$ORS $OUTPUT_RECORD_SEPARATOR/],
      '$|'                             => [qw/$OUTPUT_AUTOFLUSH/],
      '${^LAST_FH}'                    => [],
      '$^A'                            => [qw/$ACCUMULATOR/],
      '$^L'                            => [qw/$FORMAT_FORMFEED/],
      '$%'                             => [qw/$FORMAT_PAGE_NUMBER/],
      '$-'                             => [qw/$FORMAT_LINES_LEFT/],
      '$:'                             => [qw/$FORMAT_LINE_BREAK_CHARACTERS/],
      '$='                             => [qw/$FORMAT_LINES_PER_PAGE/],
      '$^'                             => [qw/$FORMAT_TOP_NAME/],
      '$~'                             => [qw/$FORMAT_NAME/],
      '${^CHILD_ERROR_NATIVE}'         => [],
      '$^E'                            => [qw/$EXTENDED_OS_ERROR/],
      '$^S'                            => [qw/$EXCEPTIONS_BEING_CAUGHT/],
      '$^W'                            => [qw/$WARNING/],
      '${^WARNING_BITS}'               => [],
      '$!'                             => [qw/$ERRNO $OS_ERROR/],
      '%!'                             => [qw/%ERRNO %OS_ERROR/],
      '$?'                             => [qw/$CHILD_ERROR/],
      '$@'                             => [qw/$EVAL_ERROR/],
      '$^C'                            => [qw/$COMPILING/],
      '$^D'                            => [qw/$DEBUGGING/],
      '${^ENCODING}'                   => [],
      '${^GLOBAL_PHASE}'               => [],
      '$^H'                            => [],
      '%^H'                            => [],
      '${^OPEN}'                       => [],
      '$^P'                            => [qw/$PERLDB/],
      '${^TAINT}'                      => [],
      '${^SAFE_LOCALES}'               => [],
      '${^UNICODE}'                    => [],
      '${^UTF8CACHE}'                  => [],
      '${^UTF8LOCALE}'                 => [],
   );

   my @query = ('-q', $val) if $val;
   my $pid = open2 (my $CHLD_OUT, my $CHLD_IN, qw/fzf -0 -1 --cycle/, @query);

   while (my ($var, $vars) = each %vars)
   {
      say $CHLD_IN "$var @$vars";
   }

   exit unless defined ($_ = <$CHLD_OUT>);
   chomp;

   waitpid $pid, 0;

   exec qw/perldoc -v/, (split)[0];
}

# Arguments
info 'perltoc' unless @ARGV;

my $page = shift;

# variables
if ($page =~ /^v.$/ or $page =~ m'^[$@%].+')
{
   $page =~ s/^v(.)$/\$$1/;
   $page = uc $page unless $page =~ /^\$[ab]$/;
   exec qw/perldoc -v/, $page;
}

# builtin functions
unless (system ("perldoc -f $page 2>/dev/null") == 0)
{
   my @pages;

   # sections & misc
   foreach (values %man)
   {
      my ($dir, $ext) = @$_;
      opendir my $dh, $dir or die "$!\n";
      push @pages, grep {!/::/ and /$page.*\.$ext/i} readdir $dh;
   }

   if (@pages)
   {
      # -q isn't needed, it's supplied to enable highlighting
      if (chomp ($_ = `printf '%s\n' @pages | fzf -q'$page' -0 -1 --cycle`))
      {
         my @parts = split /\./; # topic.section(.gz)
         exec qw/man -M/, $MANPATH, @parts > 1 ? @parts[1,0] : @parts;
      }
   } else {
      exec 'perldoc', $page;
   }
}
