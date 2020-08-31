#! /usr/bin/env perl

# OpenVPN helper for NordVPN
#
# Prerequisites:
# Install (openvpn-)update-systemd-resolved
# systemctl enable --now systemd-resolved

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;

my $S = color('bold');
my $R = color('reset');

my %countries = (
   AF => "Afghanistan",
   AL => "Albania",
   DZ => "Algeria",
   AS => "American Samoa",
   AD => "Andorra",
   AO => "Angola",
   AI => "Anguilla",
   AQ => "Antarctica",
   AG => "Antigua and Barbuda",
   AR => "Argentina",
   AM => "Armenia",
   AW => "Aruba",
   AU => "Australia",
   AT => "Austria",
   AZ => "Azerbaijan",
   BS => "Bahamas (the)",
   BH => "Bahrain",
   BD => "Bangladesh",
   BB => "Barbados",
   BY => "Belarus",
   BE => "Belgium",
   BZ => "Belize",
   BJ => "Benin",
   BM => "Bermuda",
   BT => "Bhutan",
   BO => "Bolivia (Plurinational State of)",
   BQ => "Bonaire, Sint Eustatius and Saba",
   BA => "Bosnia and Herzegovina",
   BW => "Botswana",
   BV => "Bouvet Island",
   BR => "Brazil",
   IO => "British Indian Ocean Territory (the)",
   BN => "Brunei Darussalam",
   BG => "Bulgaria",
   BF => "Burkina Faso",
   BI => "Burundi",
   CV => "Cabo Verde",
   KH => "Cambodia",
   CM => "Cameroon",
   CA => "Canada",
   KY => "Cayman Islands (the)",
   CF => "Central African Republic (the)",
   TD => "Chad",
   CL => "Chile",
   # CN => "China",
   CX => "Christmas Island",
   CC => "Cocos (Keeling) Islands (the)",
   CO => "Colombia",
   KM => "Comoros (the)",
   CD => "Congo (the Democratic Republic of the)",
   CG => "Congo (the)",
   CK => "Cook Islands (the)",
   CR => "Costa Rica",
   HR => "Croatia",
   CU => "Cuba",
   CW => "Curaçao",
   CY => "Cyprus",
   CZ => "Czechia",
   CI => "Côte d'Ivoire",
   DK => "Denmark",
   DJ => "Djibouti",
   DM => "Dominica",
   DO => "Dominican Republic (the)",
   EC => "Ecuador",
   EG => "Egypt",
   SV => "El Salvador",
   GQ => "Equatorial Guinea",
   ER => "Eritrea",
   EE => "Estonia",
   SZ => "Eswatini",
   ET => "Ethiopia",
   FK => "Falkland Islands (the) [Malvinas]",
   FO => "Faroe Islands (the)",
   FJ => "Fiji",
   FI => "Finland",
   FR => "France",
   GF => "French Guiana",
   PF => "French Polynesia",
   TF => "French Southern Territories (the)",
   GA => "Gabon",
   GM => "Gambia (the)",
   GE => "Georgia",
   DE => "Germany",
   GH => "Ghana",
   GI => "Gibraltar",
   GR => "Greece",
   GL => "Greenland",
   GD => "Grenada",
   GP => "Guadeloupe",
   GU => "Guam",
   GT => "Guatemala",
   GG => "Guernsey",
   GN => "Guinea",
   GW => "Guinea-Bissau",
   GY => "Guyana",
   HT => "Haiti",
   HM => "Heard Island and McDonald Islands",
   VA => "Holy See (the)",
   HN => "Honduras",
   HK => "Hong Kong",
   HU => "Hungary",
   IS => "Iceland",
   IN => "India",
   ID => "Indonesia",
   IR => "Iran (Islamic Republic of)",
   IQ => "Iraq",
   IE => "Ireland",
   IM => "Isle of Man",
   IL => "Israel",
   IT => "Italy",
   JM => "Jamaica",
   JP => "Japan",
   JE => "Jersey",
   JO => "Jordan",
   KZ => "Kazakhstan",
   KE => "Kenya",
   KI => "Kiribati",
   # KP => "Korea (the Democratic People's Republic of)",
   KR => "Korea (the Republic of)",
   KW => "Kuwait",
   KG => "Kyrgyzstan",
   LA => "Lao People's Democratic Republic (the)",
   LV => "Latvia",
   LB => "Lebanon",
   LS => "Lesotho",
   LR => "Liberia",
   LY => "Libya",
   LI => "Liechtenstein",
   LT => "Lithuania",
   LU => "Luxembourg",
   MO => "Macao",
   MG => "Madagascar",
   MW => "Malawi",
   MY => "Malaysia",
   MV => "Maldives",
   ML => "Mali",
   MT => "Malta",
   MH => "Marshall Islands (the)",
   MQ => "Martinique",
   MR => "Mauritania",
   MU => "Mauritius",
   YT => "Mayotte",
   MX => "Mexico",
   FM => "Micronesia (Federated States of)",
   MD => "Moldova (the Republic of)",
   MC => "Monaco",
   MN => "Mongolia",
   ME => "Montenegro",
   MS => "Montserrat",
   MA => "Morocco",
   MZ => "Mozambique",
   MM => "Myanmar",
   NA => "Namibia",
   NR => "Nauru",
   NP => "Nepal",
   NL => "Netherlands (the)",
   NC => "New Caledonia",
   NZ => "New Zealand",
   NI => "Nicaragua",
   NE => "Niger (the)",
   NG => "Nigeria",
   NU => "Niue",
   NF => "Norfolk Island",
   MP => "Northern Mariana Islands (the)",
   NO => "Norway",
   OM => "Oman",
   PK => "Pakistan",
   PW => "Palau",
   PS => "Palestine, State of",
   PA => "Panama",
   PG => "Papua New Guinea",
   PY => "Paraguay",
   PE => "Peru",
   PH => "Philippines (the)",
   PN => "Pitcairn",
   PL => "Poland",
   PT => "Portugal",
   PR => "Puerto Rico",
   QA => "Qatar",
   MK => "Republic of North Macedonia",
   RO => "Romania",
   RU => "Russian Federation (the)",
   RW => "Rwanda",
   RE => "Réunion",
   BL => "Saint Barthélemy",
   SH => "Saint Helena, Ascension and Tristan da Cunha",
   KN => "Saint Kitts and Nevis",
   LC => "Saint Lucia",
   MF => "Saint Martin (French part)",
   PM => "Saint Pierre and Miquelon",
   VC => "Saint Vincent and the Grenadines",
   WS => "Samoa",
   SM => "San Marino",
   ST => "Sao Tome and Principe",
   SA => "Saudi Arabia",
   SN => "Senegal",
   RS => "Serbia",
   SC => "Seychelles",
   SL => "Sierra Leone",
   SG => "Singapore",
   SX => "Sint Maarten (Dutch part)",
   SK => "Slovakia",
   SI => "Slovenia",
   SB => "Solomon Islands",
   SO => "Somalia",
   ZA => "South Africa",
   GS => "South Georgia and the South Sandwich Islands",
   SS => "South Sudan",
   ES => "Spain",
   LK => "Sri Lanka",
   SD => "Sudan (the)",
   SR => "Suriname",
   SJ => "Svalbard and Jan Mayen",
   SE => "Sweden",
   CH => "Switzerland",
   # SY => "Syrian Arab Republic",
   TW => "Taiwan (Province of China)",
   TJ => "Tajikistan",
   TZ => "Tanzania, United Republic of",
   TH => "Thailand",
   TL => "Timor-Leste",
   TG => "Togo",
   TK => "Tokelau",
   TO => "Tonga",
   TT => "Trinidad and Tobago",
   TN => "Tunisia",
   TR => "Turkey",
   TM => "Turkmenistan",
   TC => "Turks and Caicos Islands (the)",
   TV => "Tuvalu",
   UG => "Uganda",
   UA => "Ukraine",
   AE => "United Arab Emirates (the)",
   GB => "United Kingdom of Great Britain and Northern Ireland (the)",
   UM => "United States Minor Outlying Islands (the)",
   US => "United States of America (the)",
   UY => "Uruguay",
   UZ => "Uzbekistan",
   VU => "Vanuatu",
   VE => "Venezuela (Bolivarian Republic of)",
   VN => "Viet Nam",
   VG => "Virgin Islands (British)",
   VI => "Virgin Islands (U.S.)",
   WF => "Wallis and Futuna",
   EH => "Western Sahara",
   YE => "Yemen",
   ZM => "Zambia",
   ZW => "Zimbabwe",
   AX => "Åland Islands",
);

# Help
sub help() {
   print <<MSG;
${S}SYNOPSIS${R}
vpn.pl [-a ...] [{-c ...} or {pattern}] [-d] [-p ...] [-s [...]]
${S}OPTIONS${R}
--auth,           -a : credentials
--config,         -c : config file, or vpn country-pattern
--download,       -d : download config files
--protocol tcp    -p : defaults to udp
--show [pattern], -s : show countries
MSG
   exit;
}

# Arguments
my ($auth, $config, $download, $protocol, $show);
GetOptions (
   'a|auth=s'     => \$auth,
   'c|config=s'   => \$config,
   'd|download'   => \$download,
   'p|protocol=s' => \$protocol,
   's|show:s'     => \$show,
   'h|help'       => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

if ($download)
{
   system qw(wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip);
   exit;
}

if (defined $show)
{
   my $pattern = qr/\Q$show\E/i;
   foreach (sort { $countries{$a} cmp $countries{$b} } keys %countries)
   {
      unless ($show)
      {
         say CYAN.$_.RESET, " -> $countries{$_}";
      } else {
         if (/$pattern/ or $countries{$_} =~ $pattern)
         {
            say CYAN.$_.RESET, " -> $countries{$_}";
         }
      }
   }
   exit;
}

$auth //= "/etc/openvpn/details";

$protocol //= 'udp';
chdir "/etc/openvpn/ovpn_$protocol" or die RED."$!".RESET, "\n";

unless ($config)
{
   if (@ARGV)
   {
      $config = shift;
   } else {
      chomp ($config = `printf '%s\\0' *.ovpn | fzf --read0 -0 -1 --cycle --height 60%`);
   }
}

if ($config =~ /^\Q[a-z]+\E$/)
{
   chomp ($config = `fzf -q$config -0 -1 --cycle --height 60%`);
}

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
