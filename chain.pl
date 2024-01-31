#! /usr/bin/env perl

# Print certificate chain of trust

use strict;
use warnings;
use Term::ANSIColor ':constants';

my ($cert) = @ARGV;

# usage
my $prog = $0;
$prog =~ s#.*/##;
@ARGV == 1 or die "usage: $prog <certificate>\n";

# print certificates
$_ = `openssl crl2pkcs7 -nocrl -certfile "$cert" | openssl pkcs7 -noout -print_certs`;
chomp;

s/^.*cn\h*=\h*/FAINT.$&.RESET/megi;

print
