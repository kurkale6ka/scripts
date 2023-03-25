#! /usr/bin/env python3

"""OpenVPN helper for NordVPN

DNS leak fix requirements:
  Install (openvpn-)update-systemd-resolved
  systemctl enable --now systemd-resolved
"""

import os
import argparse
from subprocess import run, PIPE

vpn = "/etc/openvpn"
auth = vpn + "/details"
protocol = "udp"
vpn_configs = f"{vpn}/ovpn_{protocol}"
download_url = "https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip"

parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.RawTextHelpFormatter
)
grp_vpn = parser.add_argument_group("VPN")
grp_vpn.add_argument("-a", "--auth", help=f"credentials file ({vpn}/details)")
grp_vpn.add_argument(
    "-c", "--config", help=f"config file instead of pattern ({vpn_configs}/...)"
)
grp_vpn.add_argument(
    "-d",
    "--download",
    action="store_true",
    help=f"download config files:\n{download_url}",
)
grp_vpn.add_argument(
    "-p", "--protocol", type=str, choices=["udp", "tcp"], default="udp", help="protocol"
)
grp_countries = parser.add_argument_group("Countries")
grp_countries.add_argument(
    "--codes",
    action=argparse.BooleanOptionalAction,
    default=True,
    help="show country codes whit --list",
)
grp_countries.add_argument(
    "-l",
    "--list",
    default=False,
    nargs="?",
    const=1,
    help="show countries",
)
grp_countries.add_argument(
    "pattern",
    nargs="?",
    help="fuzzy country filter in order to provide a VPN config file",
)
args = parser.parse_args()

# Colors
esc = "\033["
CYAN, RED, RESET = [f"{esc}{code}m" for code in (36, 31, 0)]


class Country:
    def __init__(self, code: str, name: str):
        self._code = code
        self._name = name

    @property
    def code(self):
        return self._code

    @property
    def name(self):
        return self._name

    @property
    def info(self) -> str:
        return f"{self._code.upper()} -> {self._name}"

    def match(self, pattern: str = "") -> bool:
        if pattern == "" or pattern.lower() in self._code + self._name.lower():
            return True
        return False


class Countries:
    _all = [
        # Country("af", "Afghanistan"),
        Country("al", "Albania"),
        # Country("dz", "Algeria"),
        # Country("as", "American Samoa"),
        # Country("ad", "Andorra"),
        # Country("ao", "Angola"),
        # Country("ai", "Anguilla"),
        # Country("aq", "Antarctica"),
        # Country("ag", "Antigua and Barbuda"),
        Country("ar", "Argentina"),
        # Country("am", "Armenia"),
        # Country("aw", "Aruba"),
        Country("au", "Australia"),
        Country("at", "Austria"),
        # Country("az", "Azerbaijan"),
        # Country("bs", "Bahamas (the)"),
        # Country("bh", "Bahrain"),
        # Country("bd", "Bangladesh"),
        # Country("bb", "Barbados"),
        # Country("by", "Belarus"),
        Country("be", "Belgium"),
        # Country("bz", "Belize"),
        # Country("bj", "Benin"),
        # Country("bm", "Bermuda"),
        # Country("bt", "Bhutan"),
        # Country("bo", "Bolivia (Plurinational State of)"),
        # Country("bq", "Bonaire, Sint Eustatius and Saba"),
        Country("ba", "Bosnia and Herzegovina"),
        # Country("bw", "Botswana"),
        # Country("bv", "Bouvet Island"),
        Country("br", "Brazil"),
        # Country("io", "British Indian Ocean Territory (the)"),
        # Country("bn", "Brunei Darussalam"),
        Country("bg", "Bulgaria"),
        # Country("bf", "Burkina Faso"),
        # Country("bi", "Burundi"),
        # Country("cv", "Cabo Verde"),
        # Country("kh", "Cambodia"),
        # Country("cm", "Cameroon"),
        Country("ca", "Canada"),
        # Country("ky", "Cayman Islands (the)"),
        # Country("cf", "Central African Republic (the)"),
        # Country("td", "Chad"),
        Country("cl", "Chile"),
        # Country("cn", "China"),
        # Country("cx", "Christmas Island"),
        # Country("cc", "Cocos (Keeling) Islands (the)"),
        # Country("co", "Colombia"),
        # Country("km", "Comoros (the)"),
        # Country("cd", "Congo (the Democratic Republic of the)"),
        # Country("cg", "Congo (the)"),
        # Country("ck", "Cook Islands (the)"),
        Country("cr", "Costa Rica"),
        Country("hr", "Croatia"),
        # Country("cu", "Cuba"),
        # Country("cw", "Curaçao"),
        Country("cy", "Cyprus"),
        Country("cz", "Czechia"),
        # Country("ci", "Côte d'Ivoire"),
        Country("dk", "Denmark"),
        # Country("dj", "Djibouti"),
        # Country("dm", "Dominica"),
        # Country("do", "Dominican Republic (the)"),
        # Country("ec", "Ecuador"),
        # Country("eg", "Egypt"),
        # Country("sv", "El Salvador"),
        # Country("gq", "Equatorial Guinea"),
        # Country("er", "Eritrea"),
        Country("ee", "Estonia"),
        # Country("sz", "Eswatini"),
        # Country("et", "Ethiopia"),
        # Country("fk", "Falkland Islands (the) [Malvinas]"),
        # Country("fo", "Faroe Islands (the)"),
        # Country("fj", "Fiji"),
        Country("fi", "Finland"),
        Country("fr", "France"),
        # Country("gf", "French Guiana"),
        # Country("pf", "French Polynesia"),
        # Country("tf", "French Southern Territories (the)"),
        # Country("ga", "Gabon"),
        # Country("gm", "Gambia (the)"),
        Country("ge", "Georgia"),
        Country("de", "Germany"),
        # Country("gh", "Ghana"),
        # Country("gi", "Gibraltar"),
        Country("gr", "Greece"),
        # Country("gl", "Greenland"),
        # Country("gd", "Grenada"),
        # Country("gp", "Guadeloupe"),
        # Country("gu", "Guam"),
        # Country("gt", "Guatemala"),
        # Country("gg", "Guernsey"),
        # Country("gn", "Guinea"),
        # Country("gw", "Guinea-Bissau"),
        # Country("gy", "Guyana"),
        # Country("ht", "Haiti"),
        # Country("hm", "Heard Island and McDonald Islands"),
        # Country("va", "Holy See (the)"),
        # Country("hn", "Honduras"),
        Country("hk", "Hong Kong"),
        Country("hu", "Hungary"),
        Country("is", "Iceland"),
        Country("in", "India"),
        Country("id", "Indonesia"),
        # Country("ir", "Iran (Islamic Republic of)"),
        # Country("iq", "Iraq"),
        Country("ie", "Ireland"),
        # Country("im", "Isle of Man"),
        Country("il", "Israel"),
        Country("it", "Italy"),
        # Country("jm", "Jamaica"),
        Country("jp", "Japan"),
        # Country("je", "Jersey"),
        # Country("jo", "Jordan"),
        # Country("kz", "Kazakhstan"),
        # Country("ke", "Kenya"),
        # Country("ki", "Kiribati"),
        # Country("kp", "Korea (the Democratic People's Republic of)"),
        Country("kr", "Korea (the Republic of)"),
        # Country("kw", "Kuwait"),
        # Country("kg", "Kyrgyzstan"),
        # Country("la", "Lao People's Democratic Republic (the)"),
        Country("lv", "Latvia"),
        # Country("lb", "Lebanon"),
        # Country("ls", "Lesotho"),
        # Country("lr", "Liberia"),
        # Country("ly", "Libya"),
        # Country("li", "Liechtenstein"),
        # Country("lt", "Lithuania"),
        Country("lu", "Luxembourg"),
        # Country("mo", "Macao"),
        # Country("mg", "Madagascar"),
        # Country("mw", "Malawi"),
        Country("my", "Malaysia"),
        # Country("mv", "Maldives"),
        # Country("ml", "Mali"),
        # Country("mt", "Malta"),
        # Country("mh", "Marshall Islands (the)"),
        # Country("mq", "Martinique"),
        # Country("mr", "Mauritania"),
        # Country("mu", "Mauritius"),
        # Country("yt", "Mayotte"),
        Country("mx", "Mexico"),
        # Country("fm", "Micronesia (Federated States of)"),
        Country("md", "Moldova (the Republic of)"),
        # Country("mc", "Monaco"),
        # Country("mn", "Mongolia"),
        # Country("me", "Montenegro"),
        # Country("ms", "Montserrat"),
        # Country("ma", "Morocco"),
        # Country("mz", "Mozambique"),
        # Country("mm", "Myanmar"),
        # Country("na", "Namibia"),
        # Country("nr", "Nauru"),
        # Country("np", "Nepal"),
        Country("nl", "Netherlands (the)"),
        # Country("nc", "New Caledonia"),
        Country("nz", "New Zealand"),
        # Country("ni", "Nicaragua"),
        # Country("ne", "Niger (the)"),
        # Country("ng", "Nigeria"),
        # Country("nu", "Niue"),
        # Country("nf", "Norfolk Island"),
        # Country("mp", "Northern Mariana Islands (the)"),
        Country("no", "Norway"),
        # Country("om", "Oman"),
        # Country("pk", "Pakistan"),
        # Country("pw", "Palau"),
        # Country("ps", "Palestine, State of"),
        # Country("pa", "Panama"),
        # Country("pg", "Papua New Guinea"),
        # Country("py", "Paraguay"),
        # Country("pe", "Peru"),
        # Country("ph", "Philippines (the)"),
        # Country("pn", "Pitcairn"),
        Country("pl", "Poland"),
        Country("pt", "Portugal"),
        # Country("pr", "Puerto Rico"),
        # Country("qa", "Qatar"),
        Country("mk", "Republic of North Macedonia"),
        Country("ro", "Romania"),
        # Country("ru", "Russian Federation (the)"),
        # Country("rw", "Rwanda"),
        # Country("re", "Réunion"),
        # Country("bl", "Saint Barthélemy"),
        # Country("sh", "Saint Helena, Ascension and Tristan da Cunha"),
        # Country("kn", "Saint Kitts and Nevis"),
        # Country("lc", "Saint Lucia"),
        # Country("mf", "Saint Martin (French part)"),
        # Country("pm", "Saint Pierre and Miquelon"),
        # Country("vc", "Saint Vincent and the Grenadines"),
        # Country("ws", "Samoa"),
        # Country("sm", "San Marino"),
        # Country("st", "Sao Tome and Principe"),
        # Country("sa", "Saudi Arabia"),
        # Country("sn", "Senegal"),
        Country("rs", "Serbia"),
        # Country("sc", "Seychelles"),
        # Country("sl", "Sierra Leone"),
        Country("sg", "Singapore"),
        # Country("sx", "Sint Maarten (Dutch part)"),
        Country("sk", "Slovakia"),
        Country("si", "Slovenia"),
        # Country("sb", "Solomon Islands"),
        # Country("so", "Somalia"),
        Country("za", "South Africa"),
        # Country("gs", "South Georgia and the South Sandwich Islands"),
        # Country("ss", "South Sudan"),
        Country("es", "Spain"),
        # Country("lk", "Sri Lanka"),
        # Country("sd", "Sudan (the)"),
        # Country("sr", "Suriname"),
        # Country("sj", "Svalbard and Jan Mayen"),
        Country("se", "Sweden"),
        Country("ch", "Switzerland"),
        # Country("sy", "Syrian Arab Republic"),
        Country("tw", "Taiwan (Province of China)"),
        # Country("tj", "Tajikistan"),
        # Country("tz", "Tanzania, United Republic of"),
        Country("th", "Thailand"),
        # Country("tl", "Timor-Leste"),
        # Country("tg", "Togo"),
        # Country("tk", "Tokelau"),
        # Country("to", "Tonga"),
        # Country("tt", "Trinidad and Tobago"),
        # Country("tn", "Tunisia"),
        Country("tr", "Turkey"),
        # Country("tm", "Turkmenistan"),
        # Country("tc", "Turks and Caicos Islands (the)"),
        # Country("tv", "Tuvalu"),
        # Country("ug", "Uganda"),
        Country("ua", "Ukraine"),
        Country("ae", "United Arab Emirates (the)"),
        Country("gb", "United Kingdom of Great Britain and Northern Ireland (the)"),
        # Country("um", "United States Minor Outlying Islands (the)"),
        Country("us", "United States of America (the)"),
        # Country("uy", "Uruguay"),
        # Country("uz", "Uzbekistan"),
        # Country("vu", "Vanuatu"),
        # Country("ve", "Venezuela (Bolivarian Republic of)"),
        Country("vn", "Viet Nam"),
        # Country("vg", "Virgin Islands (British)"),
        # Country("vi", "Virgin Islands (U.S.)"),
        # Country("wf", "Wallis and Futuna"),
        # Country("eh", "Western Sahara"),
        # Country("ye", "Yemen"),
        # Country("zm", "Zambia"),
        # Country("zw", "Zimbabwe"),
        # Country("ax", "Åland Islands)",
    ]

    # TODO: uk fix
    # countries['uk'] = countries['gb']

    @classmethod
    def list(cls, codes: bool = True, filter: str = "") -> None:
        for country in cls._all:
            if country.match(filter):
                if codes:
                    print(country.info)
                    # TODO: code in cyan
                    # print(code.replace('uk', 'gb').upper(), '->', country)
                else:
                    print(country.name)


if __name__ == "__main__":
    # # TODO: fix + add to other scripts
    # if args.codes and not args.list:
    #     parser.error("--codes requires --list")

    if args.list:
        if args.list == 1:
            Countries().list(args.codes)
        elif args.list:
            Countries().list(args.codes, filter=args.list)
        exit()

    if args.download:
        os.execlp("wget", "wget", download_url)

    if os.geteuid() != 0:
        exit(RED + "Run as root" + RESET)

    fzf = ["fzf", "-0", "-1", "--cycle", "--height", "60%"]
    if args.pattern:
        fzf.extend(("-q", args.pattern))

    with os.scandir(vpn_configs) as ls:
        configs = "\n".join(
            sorted(file.name for file in ls if file.name.endswith(".ovpn"))
        )
        config = run(fzf, input=configs, stdout=PIPE, text=True)
        config = vpn_configs + "/" + config.stdout.rstrip()

    os.execlp(
        "openvpn",
        "openvpn",
        "--config",
        config,
        "--script-security",
        "2",
        "--setenv",
        "PATH",
        "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "--up",
        "/usr/bin/update-systemd-resolved",
        "--up-restart",
        "--down",
        "/usr/bin/update-systemd-resolved",
        "--down-pre",
        "--dhcp-option",
        "DOMAIN-ROUTE",
        ".",
        "--auth-user-pass",
        auth,
    )
