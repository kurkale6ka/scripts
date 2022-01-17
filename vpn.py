#! /usr/bin/env python3

'''OpenVPN helper for NordVPN

DNS leak fix:
  Install (openvpn-)update-systemd-resolved
  systemctl enable --now systemd-resolved
'''

import os
import argparse
from subprocess import run, PIPE

vpn          = '/etc/openvpn'
auth         = vpn + '/details'
protocol     = 'udp'
vpn_configs  = f'{vpn}/ovpn_{protocol}'
download_url = 'https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip'

parser = argparse.ArgumentParser(usage="vpn [options] [pattern] (or use zsh completion)")
parser.add_argument("pattern", nargs='?')
parser.add_argument("-a", "--auth", help=f"credentials file ({vpn}/details)")
parser.add_argument("-b", "--batch", action="store_true", help="no codes with --list")
parser.add_argument("-c", "--config", help=f"config file instead of pattern ({vpn_configs}/...)")
parser.add_argument("-d", "--download", action="store_true", help=f"download config files ({download_url})")
parser.add_argument("-l", "--list", default=None, nargs='?', const=1, help="show countries")
parser.add_argument("-p", "--protocol", help="defaults to udp")
args = parser.parse_args()

# Colors
esc = '\033['
CYAN, RED, RESET = [f'{esc}{code}m' for code in (36, 31, 0)]

if not any((args.download, args.list)):
   if os.geteuid() != 0:
      exit(RED + 'Run as root' + RESET)

countries = {
# "af": "Afghanistan",
"al": "Albania",
# "dz": "Algeria",
# "as": "American Samoa",
# "ad": "Andorra",
# "ao": "Angola",
# "ai": "Anguilla",
# "aq": "Antarctica",
# "ag": "Antigua and Barbuda",
"ar": "Argentina",
# "am": "Armenia",
# "aw": "Aruba",
"au": "Australia",
"at": "Austria",
# "az": "Azerbaijan",
# "bs": "Bahamas (the)",
# "bh": "Bahrain",
# "bd": "Bangladesh",
# "bb": "Barbados",
# "by": "Belarus",
"be": "Belgium",
# "bz": "Belize",
# "bj": "Benin",
# "bm": "Bermuda",
# "bt": "Bhutan",
# "bo": "Bolivia (Plurinational State of)",
# "bq": "Bonaire, Sint Eustatius and Saba",
"ba": "Bosnia and Herzegovina",
# "bw": "Botswana",
# "bv": "Bouvet Island",
"br": "Brazil",
# "io": "British Indian Ocean Territory (the)",
# "bn": "Brunei Darussalam",
"bg": "Bulgaria",
# "bf": "Burkina Faso",
# "bi": "Burundi",
# "cv": "Cabo Verde",
# "kh": "Cambodia",
# "cm": "Cameroon",
"ca": "Canada",
# "ky": "Cayman Islands (the)",
# "cf": "Central African Republic (the)",
# "td": "Chad",
"cl": "Chile",
# "cn": "China",
# "cx": "Christmas Island",
# "cc": "Cocos (Keeling) Islands (the)",
# "co": "Colombia",
# "km": "Comoros (the)",
# "cd": "Congo (the Democratic Republic of the)",
# "cg": "Congo (the)",
# "ck": "Cook Islands (the)",
"cr": "Costa Rica",
"hr": "Croatia",
# "cu": "Cuba",
# "cw": "Curaçao",
"cy": "Cyprus",
"cz": "Czechia",
# "ci": "Côte d'Ivoire",
"dk": "Denmark",
# "dj": "Djibouti",
# "dm": "Dominica",
# "do": "Dominican Republic (the)",
# "ec": "Ecuador",
# "eg": "Egypt",
# "sv": "El Salvador",
# "gq": "Equatorial Guinea",
# "er": "Eritrea",
"ee": "Estonia",
# "sz": "Eswatini",
# "et": "Ethiopia",
# "fk": "Falkland Islands (the) [Malvinas]",
# "fo": "Faroe Islands (the)",
# "fj": "Fiji",
"fi": "Finland",
"fr": "France",
# "gf": "French Guiana",
# "pf": "French Polynesia",
# "tf": "French Southern Territories (the)",
# "ga": "Gabon",
# "gm": "Gambia (the)",
"ge": "Georgia",
"de": "Germany",
# "gh": "Ghana",
# "gi": "Gibraltar",
"gr": "Greece",
# "gl": "Greenland",
# "gd": "Grenada",
# "gp": "Guadeloupe",
# "gu": "Guam",
# "gt": "Guatemala",
# "gg": "Guernsey",
# "gn": "Guinea",
# "gw": "Guinea-Bissau",
# "gy": "Guyana",
# "ht": "Haiti",
# "hm": "Heard Island and McDonald Islands",
# "va": "Holy See (the)",
# "hn": "Honduras",
"hk": "Hong Kong",
"hu": "Hungary",
"is": "Iceland",
"in": "India",
"id": "Indonesia",
# "ir": "Iran (Islamic Republic of)",
# "iq": "Iraq",
"ie": "Ireland",
# "im": "Isle of Man",
"il": "Israel",
"it": "Italy",
# "jm": "Jamaica",
"jp": "Japan",
# "je": "Jersey",
# "jo": "Jordan",
# "kz": "Kazakhstan",
# "ke": "Kenya",
# "ki": "Kiribati",
# "kp": "Korea (the Democratic People's Republic of)",
"kr": "Korea (the Republic of)",
# "kw": "Kuwait",
# "kg": "Kyrgyzstan",
# "la": "Lao People's Democratic Republic (the)",
"lv": "Latvia",
# "lb": "Lebanon",
# "ls": "Lesotho",
# "lr": "Liberia",
# "ly": "Libya",
# "li": "Liechtenstein",
# "lt": "Lithuania",
"lu": "Luxembourg",
# "mo": "Macao",
# "mg": "Madagascar",
# "mw": "Malawi",
"my": "Malaysia",
# "mv": "Maldives",
# "ml": "Mali",
# "mt": "Malta",
# "mh": "Marshall Islands (the)",
# "mq": "Martinique",
# "mr": "Mauritania",
# "mu": "Mauritius",
# "yt": "Mayotte",
"mx": "Mexico",
# "fm": "Micronesia (Federated States of)",
"md": "Moldova (the Republic of)",
# "mc": "Monaco",
# "mn": "Mongolia",
# "me": "Montenegro",
# "ms": "Montserrat",
# "ma": "Morocco",
# "mz": "Mozambique",
# "mm": "Myanmar",
# "na": "Namibia",
# "nr": "Nauru",
# "np": "Nepal",
"nl": "Netherlands (the)",
# "nc": "New Caledonia",
"nz": "New Zealand",
# "ni": "Nicaragua",
# "ne": "Niger (the)",
# "ng": "Nigeria",
# "nu": "Niue",
# "nf": "Norfolk Island",
# "mp": "Northern Mariana Islands (the)",
"no": "Norway",
# "om": "Oman",
# "pk": "Pakistan",
# "pw": "Palau",
# "ps": "Palestine, State of",
# "pa": "Panama",
# "pg": "Papua New Guinea",
# "py": "Paraguay",
# "pe": "Peru",
# "ph": "Philippines (the)",
# "pn": "Pitcairn",
"pl": "Poland",
"pt": "Portugal",
# "pr": "Puerto Rico",
# "qa": "Qatar",
"mk": "Republic of North Macedonia",
"ro": "Romania",
# "ru": "Russian Federation (the)",
# "rw": "Rwanda",
# "re": "Réunion",
# "bl": "Saint Barthélemy",
# "sh": "Saint Helena, Ascension and Tristan da Cunha",
# "kn": "Saint Kitts and Nevis",
# "lc": "Saint Lucia",
# "mf": "Saint Martin (French part)",
# "pm": "Saint Pierre and Miquelon",
# "vc": "Saint Vincent and the Grenadines",
# "ws": "Samoa",
# "sm": "San Marino",
# "st": "Sao Tome and Principe",
# "sa": "Saudi Arabia",
# "sn": "Senegal",
"rs": "Serbia",
# "sc": "Seychelles",
# "sl": "Sierra Leone",
"sg": "Singapore",
# "sx": "Sint Maarten (Dutch part)",
"sk": "Slovakia",
"si": "Slovenia",
# "sb": "Solomon Islands",
# "so": "Somalia",
"za": "South Africa",
# "gs": "South Georgia and the South Sandwich Islands",
# "ss": "South Sudan",
"es": "Spain",
# "lk": "Sri Lanka",
# "sd": "Sudan (the)",
# "sr": "Suriname",
# "sj": "Svalbard and Jan Mayen",
"se": "Sweden",
"ch": "Switzerland",
# "sy": "Syrian Arab Republic",
"tw": "Taiwan (Province of China)",
# "tj": "Tajikistan",
# "tz": "Tanzania, United Republic of",
"th": "Thailand",
# "tl": "Timor-Leste",
# "tg": "Togo",
# "tk": "Tokelau",
# "to": "Tonga",
# "tt": "Trinidad and Tobago",
# "tn": "Tunisia",
"tr": "Turkey",
# "tm": "Turkmenistan",
# "tc": "Turks and Caicos Islands (the)",
# "tv": "Tuvalu",
# "ug": "Uganda",
"ua": "Ukraine",
"ae": "United Arab Emirates (the)",
"gb": "United Kingdom of Great Britain and Northern Ireland (the)",
# "um": "United States Minor Outlying Islands (the)",
"us": "United States of America (the)",
# "uy": "Uruguay",
# "uz": "Uzbekistan",
# "vu": "Vanuatu",
# "ve": "Venezuela (Bolivarian Republic of)",
"vn": "Viet Nam",
# "vg": "Virgin Islands (British)",
# "vi": "Virgin Islands (U.S.)",
# "wf": "Wallis and Futuna",
# "eh": "Western Sahara",
# "ye": "Yemen",
# "zm": "Zambia",
# "zw": "Zimbabwe",
# "ax": "Åland Islands"
}

# # uk fix
# countries['uk'] = countries['gb']

def list(pattern=''):
   for code, country in countries.items():
      if not pattern or pattern.lower() in code + country.lower():
         if args.batch:
            print(country)
         else:
            print(CYAN + code.upper() + RESET, '->', country)
            # print(code.replace('uk', 'gb').upper(), '->', country)

if args.list == 1:
   list()
elif args.list:
   list(args.list)
else:
   fzf = ['fzf', '-0', '-1', '--cycle', '--height', '60%']
   if args.pattern:
      fzf.extend(('-q', args.pattern))

   with os.scandir(vpn_configs) as ls:
      configs = '\n'.join(sorted(file.name for file in ls if file.name.endswith('.ovpn')))
      config = run(fzf, input=configs, stdout=PIPE, text=True)
      config = vpn_configs + '/' + config.stdout.rstrip()

   os.execlp('openvpn', 'openvpn',
   '--config', config,
   '--script-security', '2',
   '--setenv', 'PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
   '--up', '/usr/bin/update-systemd-resolved',
   '--up-restart',
   '--down', '/usr/bin/update-systemd-resolved',
   '--down-pre',
   '--dhcp-option', 'DOMAIN-ROUTE', '.',
   '--auth-user-pass', auth)
