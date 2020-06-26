#! /usr/bin/env perl

# Generate a postfix Makefile for Berkeley DB files (.db)
#
# http://www.postfix.org/DATABASE_README.html#safe_db

use strict;
use warnings;
use feature 'say';
use File::Basename 'fileparse';

# chdir '/etc/postfix' or die;

my @dbs = glob "'*.db'" or die "No dbs found\n";

# open my $makefile, '>>', 'Makefile' or die "Can't open >> Makefile: $!\n";
# select $makefile;

say 'Creating rules for:';
say "* $_" foreach @dbs;

# sanitize whitespaces
if (@dbs > 1)
{
   say 'databases: \\';
   say "$_ \\" foreach @dbs;
} else {
   say "databases: @dbs";
}

print "\n";

foreach my $db (@dbs)
{
   my $base = fileparse ($db, '.db');
   my $in = "$base.in";

   my $cmd = $db =~ /aliases/ ? 'postalias' : 'postmap';

   # canonical.in -> canonical
   symlink $base, $in;

   say <<RULE
$db: $in
	\@echo updating "$db"...
	\@$cmd "$in"
	\@mv "$in.db" "$db"
RULE
}
