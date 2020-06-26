#! /usr/bin/env perl

# Generate a postfix Makefile for Berkeley DB files (.db)
#
# http://www.postfix.org/DATABASE_README.html#safe_db

use strict;
use warnings;
use feature 'say';
use File::Basename 'fileparse';

chdir '/etc/postfix' or die;

my @dbs = glob "'*.db'" or die "No dbs found\n";

open my $makefile, '>>', 'Makefile' or die "Can't open >> Makefile: $!\n";

say 'Creating rules for:';
say "* $_" foreach @dbs;

my $count = 0;

select $makefile;

# Default goal
print 'databases: ';

foreach (@dbs)
{
   print;
   print ' \\' unless ++$count == @dbs;
   print "\n";
}

$count = 0;
print "\n";

# Rules
foreach my $db (@dbs)
{
   my $base = fileparse ($db, '.db');
   my $in = "$base.in";

   my $cmd = $db =~ /aliases/ ? 'postalias' : 'postmap';

   # canonical.in -> canonical
   symlink $base, $in;

   print <<RULE;
$db: $in
        \@echo updating "$db"...
        \@$cmd "$in"
        \@mv "$in.db" "$db"
RULE
   print "\n" unless ++$count == @dbs;
}
