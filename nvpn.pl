#! /usr/bin/env perl

# pacaur -S openvpn-update-systemd-resolved
# systemctl start systemd-resolved

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

# Help
sub help() {
   say 'nvpn.pl -a auth -c config';
   exit;
}

# Arguments
my ($auth, $config);
GetOptions (
   'a|auth=s'   => \$auth,
   'c|config=s' => \$config,
   'h|help'     => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

system
'openvpn',
'--config', $config,
'--script-security', 2,
'--setenv', 'PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
'--up', '/etc/openvpn/scripts/update-systemd-resolved',
'--up-restart',
'--down', '/etc/openvpn/scripts/update-systemd-resolved',
'--down-pre',
'--dhcp-option', 'DOMAIN-ROUTE', '.',
'--auth-user-pass', $auth
   or die RED."$!".RESET, "\n";
