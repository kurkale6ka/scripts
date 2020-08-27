#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
sub help() {
   say "$0 -a auth -c config";
   exit;
}

# Arguments
my ($config, $auth);
GetOptions (
   'a|auth=s'   => \$auth,
   'c|config=s' => \$config,
   'h|help'     => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

system
'openvpn',
'--config', "/etc/openvpn/ovpn_udp/$config",
'--script-security', 2,
'--up',   '/etc/openvpn/scripts/update-systemd-resolved',
'--down', '/etc/openvpn/scripts/update-systemd-resolved',
'--auth-user-pass', $auth
   or die RED."$!".RESET, "\n";
