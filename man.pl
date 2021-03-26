#! /usr/bin/env perl

# Easier access to Perl help topics

use v5.12;
use warnings;
use utf8;
use re '/aa';
use Getopt::Long qw/GetOptions :config bundling no_ignore_case pass_through/;
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
my $MANSECT = join ':', uniq map {        @$_[1]} values %man;

my $local_man;

if ($ENV{PERL_LOCAL_LIB_ROOT})
{
   $local_man = "$ENV{PERL_LOCAL_LIB_ROOT}/man";
   $MANPATH .= ":$local_man";
}

# Get info: try man, then perldoc
sub info
{
   (my $topic = shift) =~ s/'/'"'"'/g;
   unless (system ("man -M $MANPATH -S $MANSECT '$topic' 2>/dev/null") == 0)
   {
      exec 'perldoc', $topic;
   }
   exit;
}

# Usage
my $help = << '──────────────────';
Easier access to Perl help topics

mp          : locate help sections
mp section  : (perl)re,run,...
mp keyword  : builtin functions, identifiers, ...
mp [$@%]... : variable, mp v. for 2-chars variables (e.g v- for $-)
mp -v       : variables
mp -[l]m    : core (or local) modules
mp -[l]M    : core (or local) modules code <= export PERLDOC_SRC_PAGER=$EDITOR
mp -        : file test operators

- fzf is needed for -v, -m, -M and <section/topic> lookup
  alt-enter will swap -m/-M actions

- extra options will be passed through to perldoc (ex: -q for FAQ search)

- mp aka 'man Perl' is an alias to this script
──────────────────

# Options
my ($local, $module, $opt, $val);

GetOptions (
   'v|variables:s'   => \&variables,
   'l|local'         => sub { $local = 1 if $local_man },
   'm|module:s'      => sub { $module++; ($opt, $val) = @_ },
   'M|module-view:s' => sub { $module++; ($opt, $val) = @_ },
   'h|help'          => sub { print $help; exit },
   ''                => sub { exec qw/perldoc -f -/ },
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

module ($opt, $val) if $module;

sub module
{
   $val =~ s/'/'"'"'/g;
   my @modules;

   if ($local)
   {
      opendir my $LSEC, $local_man or die "$!\n";
      my @sections = grep /^man\d$/, readdir $LSEC;

      foreach (@sections)
      {
         opendir my $LMAN, "$local_man/$_" or die "$!\n";
         push @modules, map {substr $_, 0, -2} readdir $LMAN;
      }
   } else {
      my $modules = Module::CoreList::find_version $];
      @modules = keys %$modules;
   }

   if ($val)
   {
      $_ = `printf '%s\n' @modules | fzf -q'$val' --expect='alt-enter' -0 -1 --cycle`;
   } else {
      $_ = `printf '%s\n' @modules | fzf          --expect='alt-enter' -0 -1 --cycle`;
   }

   chomp;
   exit unless $_;

   # key is either empty or alt+Enter
   my ($key, $page) = split /\n/;

   if (($opt eq 'm' and !$key) or ($opt eq 'M' and $key))
   {
      info $page;
   } else {
      exec qw/perldoc -m/, $page; # view code
   }
}

sub variables
{
   my ($opt, $val) = @_;

   # perldoc -MPod::Simple::Text -T perlvar | egrep '^\s{4}[$@%]'
   my %vars = (
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
if ($page =~ /^v(.)$/ or $page =~ m'^[$@%].+')
{
   $page = '$'.$1 if defined $1;
   $page = uc $page unless $page =~ /^\$[ab]$/;
   exec qw/perldoc -v/, $page;
}

$page =~ s/'/'"'"'/g;

# builtin functions
unless (system ("perldoc -f '$page' 2>/dev/null") == 0)
{
   my @pages;

   # sections & misc
   foreach (values %man)
   {
      my ($dir, $ext) = @$_;
      opendir my $DH, $dir or die "$!\n";
      push @pages, grep {!/::/ and /\Q$page\E.*\.$ext/i} readdir $DH;
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
