#! /usr/bin/env perl

# OpenVPN helper for NordVPN
#
# OpenVPN DNS leak fix:
# Install (openvpn-)update-systemd-resolved
# systemctl enable --now systemd-resolved

use strict;
use warnings;
use feature 'say';
use Term::ANSIColor qw/color :constants/;
use Getopt::Long qw/GetOptions :config bundling/;
use List::Util 'any';

my $vpn = '/etc/openvpn';
my $auth = "$vpn/details";
my $protocol = 'udp';

sub help()
{
   print <<MSG;
vpn.pl [-a|--auth ...]                : credentials file ($vpn/details)
       [-b|--batch]                   : no codes with 'show'
       [-c|--config ...] or [pattern] : config file ($vpn/ovpn_<proto>/...)
       [-d|--download]                : download config files
       [-i|--ignore]                  : ignore excluded countries
       [-p|--protocol ...]            : defaults to udp
       [-s|--show [pattern]]          : show countries
MSG
   exit;
}

# Arguments
my ($batch, $config, $download, $ignore, $show);
GetOptions (
   'a|auth=s'     => \$auth,
   'b|batch'      => \$batch,
   'c|config=s'   => \$config,
   'd|download'   => \$download,
   'i|ignore'     => \$ignore,
   'p|protocol=s' => \$protocol,
   's|show:s'     => \$show,
   'h|help'       => \&help
) or die RED.'Error in command line arguments'.RESET, "\n";

unless (any {defined} ($download, $show))
{
   (getpwuid $>)[0] eq 'root' or die RED.'Run as root'.RESET, "\n";
}

# China, North Korea, Syria
my @exclusions = qw/CN KP SY/;

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
   CN => "China",
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
   KP => "Korea (the Democratic People's Republic of)",
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
   SY => "Syrian Arab Republic",
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

delete @countries{@exclusions} unless $ignore;

# get config
unless (any {defined} ($config, $download, $show))
{
   if (@ARGV)
   {
      $config = shift;
   } else {
      chomp ($config = `cd '$vpn/ovpn_$protocol' && printf '%s\\0' *.ovpn | fzf --read0 -0 -1 --cycle --height 60%`);
      $config or die RED.'no match'.RESET, "\n";
      $config = "$vpn/ovpn_$protocol/$config";
   }
}

# vpn --config code/country
if (defined $config and $config =~ /^[a-z]+$/)
{
   my $country;

   if (length $config == 2)
   {
      # code
      $country = $config;
   } else {
      my (%codes, $num);
      my $pattern = qr/\Q$config\E/i;

      foreach (sort { $countries{$a} cmp $countries{$b} } keys %countries)
      {
         $codes{++$num} = $_ if $countries{$_} =~ /$pattern/;
      }

      %codes or die RED.'no match'.RESET, "\n";

      unless (scalar keys %codes == 1)
      {
         foreach (sort { $countries{$codes{$a}} cmp $countries{$codes{$b}} } keys %codes)
         {
            say "$_. ", CYAN.$codes{$_}.RESET, " -> $countries{$codes{$_}}";
         }

         print 'Choose: ';
         chomp ($_ = <STDIN>);
         $country = lc $codes{$_};
      } else {
         $country = lc $codes{1};
      }
   }

   chomp ($config = `cd '$vpn/ovpn_$protocol' && printf '%s\\0' *.ovpn | fzf --read0 -0 -1 --cycle --height 60% -q'^$country'`);
   $config or die RED.'no match'.RESET, "\n";
   $config = "$vpn/ovpn_$protocol/$config";
}

if ($download)
{
   exec qw(wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip);
}

if (defined $show)
{
   my $pattern = qr/\Q$show\E/i;

   foreach (sort { $countries{$a} cmp $countries{$b} } keys %countries)
   {
      unless ($show)
      {
         # all
         unless ($batch)
         {
            say CYAN.$_.RESET, " -> $countries{$_}";
         } else {
            say $countries{$_};
         }
      } else {
         if (/$pattern/ or $countries{$_} =~ $pattern)
         {
            unless ($batch)
            {
               say CYAN.$_.RESET, " -> $countries{$_}";
            } else {
               say $countries{$_};
            }
         }
      }
   }
   exit;
}

exec 'openvpn',
'--config', $config,
'--script-security', 2,
'--setenv', 'PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
'--up', "$vpn/scripts/update-systemd-resolved",
'--up-restart',
'--down', "$vpn/scripts/update-systemd-resolved",
'--down-pre',
'--dhcp-option', 'DOMAIN-ROUTE', '.',
'--auth-user-pass', $auth;
