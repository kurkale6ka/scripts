#! /usr/bin/env perl

while (<DATA>) {
   ($val1, $val2) = split;
   $db{$val1}{$val2}++;
}

while (($key, $val) = each %db) {
   while (($key2, $val2) = each %$val) {
      print "$key: $val2 $key2\n";
   }
}

__DATA__
apples blue
berries red
tomatoes green
apples red
apples blue
berries red
tomatoes green
berries red
apples blue
berries green
