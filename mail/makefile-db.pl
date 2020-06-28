#! /usr/bin/env perl

# DEPRECATED
#
#   GNU make can do this for you,
#   use the Makefile included at the end of this script
#
# Generate a Makefile for postfix Berkeley DB (.db) files
#
#   http://www.postfix.org/DATABASE_README.html#safe_db

use strict;
use warnings;
use feature 'say';
use File::Basename 'fileparse';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long 'GetOptions';

my  $BLUE = color('ansi69');
my  $CYAN = color('ansi45');
my   $RED = color('red');
my $RESET = color('reset');

# Help
sub help() {
   say "$0 [--dry-run(-n)]";
   say 'Generate a Makefile for postfix Berkeley DB (.db) files';
   exit;
}

# Options
my $dry;
GetOptions(
   'n|dry-run' => \$dry,
   'help'      => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

# Initialisations
chdir '/etc/postfix' or
die RED."failed to cd in $BLUE/etc/postfix$RESET $RED- $!".RESET, "\n";

my @dbs = glob "'*.db'" or
die RED.'no Berkeley DBs (.db) found'.RESET, "\n";

unless ($dry)
{
   open my $makefile, '>', 'Makefile' or
   die RED."couldn't open Makefile: $!".RESET, "\n";

   # List rules
   say 'Creating rules for:';
   say "* ${CYAN}$_${RESET}" foreach @dbs;

   # Write to Makefile
   select $makefile;
}

# Default goal
my $count = 0;

print 'databases: ';

foreach (@dbs)
{
   print;
   print ' \\' unless ++$count == @dbs;
   print "\n";
}
print "\n";

# Rules
$count = 0;

foreach my $db (@dbs)
{
   my $base = fileparse ($db, '.db');
   my $in = "$base.in";

   my $cmd = $db =~ /aliases/ ? 'postalias' : 'postmap';

   # ex: canonical.in -> canonical
   symlink $base, $in;

   print <<RULE;
$db: $in
	\@echo updating "$db"...
	\@$cmd "$in"
	\@mv "$in.db" "$db"
RULE
   print "\n" unless ++$count == @dbs;
}

__DATA__

# Makefile for postfix Berkeley DB (.db) files
#
#   http://www.postfix.org/DATABASE_README.html#safe_db
#
# Requirement:
#
#   create links
#   ex: canonical.in -> canonical
#   for d in *.db; do ln -sf "${d%.db}" "${d%.db}.in"; done
#
# Warning:
#
#   pattern rules will fail if dbs have whitespaces in their names

DBS = $(wildcard *.db)

databases: ${DBS}

aliases.db: aliases.in
	@echo updating aliases.db...
	@postalias aliases.in
	@mv aliases.in.db aliases.db

%.db: %.in
	@echo updating "$@"...
	@postmap "$<"
	@mv "$<.db" "$@"
