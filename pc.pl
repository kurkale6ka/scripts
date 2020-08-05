#! /usr/bin/env perl

# fuzzy search for pass passwords
#
# pass - the standard UNIX password manager
# https://www.passwordstore.org/

use strict;
use warnings;
use feature 'say';
use File::Glob ':bsd_glob';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use File::Basename 'basename';
use File::Path 'make_path';
use List::Util 'any';

my $store = glob '~/.password-store';

my $BLUE = color('ansi69');
my $CYAN = color('ansi45');
my $S = color('bold');
my $R = color('reset');

# Help
sub help() {
   print <<MSG;
${S}SYNOPSIS${R}
pc [-o] : copy password
${S}OPTIONS${R}
${S}DESCRIPTION${R}
MSG
   exit;
}

# Arguments
GetOptions (
   'h|help' => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";


