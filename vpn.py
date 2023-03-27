#! /usr/bin/env python3

"""Linux OpenVPN helper for NordVPN

Use FZF to find a per-country VPN config.
Plug DNS leaks.

DNS leak fix requirements:
- Install (openvpn-)update-systemd-resolved
- systemctl enable --now systemd-resolved
"""

from os import scandir, execlp
from argparse import ArgumentParser, RawTextHelpFormatter, BooleanOptionalAction
from subprocess import run, PIPE

vpn = "/etc/openvpn"
auth = vpn + "/details"
download_url = "https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip"

parser = ArgumentParser(description=__doc__, formatter_class=RawTextHelpFormatter)
grp_vpn = parser.add_argument_group("VPN")
grp_vpn.add_argument(
    "--credentials", default=auth, help=f"VPN credentials file ({vpn}/details)"
)
grp_vpn.add_argument(
    "-d",
    "--download",
    action="store_true",
    help=f"download VPN config files from:\n{download_url}",
)
grp_vpn.add_argument(
    "-p", "--protocol", type=str, choices=["udp", "tcp"], default="udp", help="protocol"
)
grp_vpn_cfg = parser.add_argument_group("VPN config file")
grp_vpn_cfg.add_argument(
    "-s", "--source", default=vpn, help=f"config files source folder"
)
grp_vpn_cfg.add_argument(
    "pattern",
    nargs="?",
    default=False,
    help="fuzzy country filter in order to provide a VPN config file",
)
grp_vpn_cfg.add_argument("-c", "--config", help=f"individual config file path")
grp_countries = parser.add_argument_group("Countries")
grp_countries.add_argument(
    "-l",
    "--list",
    nargs="?",
    default=False,
    const=1,
    help="show countries where Netflix is available",
)
grp_countries.add_argument(
    "-a", "--all", action="store_true", help="show all countries"
)
grp_countries.add_argument(
    "--codes",
    action=BooleanOptionalAction,
    default=True,
    help="display country codes (requires --list)",
)
args = parser.parse_args()

# Colors
ESC = "\033["
CYAN, RED, RESET = (f"{ESC}{code}m" for code in (36, 31, 0))


class Country:
    def __init__(self, code: str, name: str, netflix: bool = False):
        self._code = code
        self._name = name
        self._netflix = netflix

    @property
    def code(self) -> str:
        return self._code

    @property
    def name(self) -> str:
        return self._name

    @property
    def netflix(self) -> bool:
        return self._netflix

    @property
    def info(self) -> str:
        """code -> name"""
        return f"{CYAN + self._code.upper() + RESET} -> {self._name}"

    def match(self, pattern: str = "") -> bool:
        """compare against the fuzzy country filter"""
        if pattern == "" or pattern.lower() in self._code + self._name.lower():
            return True
        return False


class Countries:
    _all = [
        Country("af", "Afghanistan"),
        Country("al", "Albania", netflix=True),
        Country("dz", "Algeria"),
        Country("as", "American Samoa"),
        Country("ad", "Andorra"),
        Country("ao", "Angola"),
        Country("ai", "Anguilla"),
        Country("aq", "Antarctica"),
        Country("ag", "Antigua and Barbuda"),
        Country("ar", "Argentina", netflix=True),
        Country("am", "Armenia"),
        Country("aw", "Aruba"),
        Country("au", "Australia", netflix=True),
        Country("at", "Austria", netflix=True),
        Country("az", "Azerbaijan"),
        Country("bs", "Bahamas (the)"),
        Country("bh", "Bahrain"),
        Country("bd", "Bangladesh"),
        Country("bb", "Barbados"),
        Country("by", "Belarus"),
        Country("be", "Belgium", netflix=True),
        Country("bz", "Belize"),
        Country("bj", "Benin"),
        Country("bm", "Bermuda"),
        Country("bt", "Bhutan"),
        Country("bo", "Bolivia (Plurinational State of)"),
        Country("bq", "Bonaire, Sint Eustatius and Saba"),
        Country("ba", "Bosnia and Herzegovina", netflix=True),
        Country("bw", "Botswana"),
        Country("bv", "Bouvet Island"),
        Country("br", "Brazil", netflix=True),
        Country("io", "British Indian Ocean Territory (the)"),
        Country("bn", "Brunei Darussalam"),
        Country("bg", "Bulgaria", netflix=True),
        Country("bf", "Burkina Faso"),
        Country("bi", "Burundi"),
        Country("cv", "Cabo Verde"),
        Country("kh", "Cambodia"),
        Country("cm", "Cameroon"),
        Country("ca", "Canada", netflix=True),
        Country("ky", "Cayman Islands (the)"),
        Country("cf", "Central African Republic (the)"),
        Country("td", "Chad"),
        Country("cl", "Chile", netflix=True),
        Country("cn", "China"),
        Country("cx", "Christmas Island"),
        Country("cc", "Cocos (Keeling) Islands (the)"),
        Country("co", "Colombia"),
        Country("km", "Comoros (the)"),
        Country("cd", "Congo (the Democratic Republic of the)"),
        Country("cg", "Congo (the)"),
        Country("ck", "Cook Islands (the)"),
        Country("cr", "Costa Rica", netflix=True),
        Country("hr", "Croatia", netflix=True),
        Country("cu", "Cuba"),
        Country("cw", "Curaçao"),
        Country("cy", "Cyprus", netflix=True),
        Country("cz", "Czechia", netflix=True),
        Country("ci", "Côte d'Ivoire"),
        Country("dk", "Denmark", netflix=True),
        Country("dj", "Djibouti"),
        Country("dm", "Dominica"),
        Country("do", "Dominican Republic (the)"),
        Country("ec", "Ecuador"),
        Country("eg", "Egypt"),
        Country("sv", "El Salvador"),
        Country("gq", "Equatorial Guinea"),
        Country("er", "Eritrea"),
        Country("ee", "Estonia", netflix=True),
        Country("sz", "Eswatini"),
        Country("et", "Ethiopia"),
        Country("fk", "Falkland Islands (the) [Malvinas]"),
        Country("fo", "Faroe Islands (the)"),
        Country("fj", "Fiji"),
        Country("fi", "Finland", netflix=True),
        Country("fr", "France", netflix=True),
        Country("gf", "French Guiana"),
        Country("pf", "French Polynesia"),
        Country("tf", "French Southern Territories (the)"),
        Country("ga", "Gabon"),
        Country("gm", "Gambia (the)"),
        Country("ge", "Georgia", netflix=True),
        Country("de", "Germany", netflix=True),
        Country("gh", "Ghana"),
        Country("gi", "Gibraltar"),
        Country("gr", "Greece", netflix=True),
        Country("gl", "Greenland"),
        Country("gd", "Grenada"),
        Country("gp", "Guadeloupe"),
        Country("gu", "Guam"),
        Country("gt", "Guatemala"),
        Country("gg", "Guernsey"),
        Country("gn", "Guinea"),
        Country("gw", "Guinea-Bissau"),
        Country("gy", "Guyana"),
        Country("ht", "Haiti"),
        Country("hm", "Heard Island and McDonald Islands"),
        Country("va", "Holy See (the)"),
        Country("hn", "Honduras"),
        Country("hk", "Hong Kong", netflix=True),
        Country("hu", "Hungary", netflix=True),
        Country("is", "Iceland", netflix=True),
        Country("in", "India", netflix=True),
        Country("id", "Indonesia", netflix=True),
        Country("ir", "Iran (Islamic Republic of)"),
        Country("iq", "Iraq"),
        Country("ie", "Ireland", netflix=True),
        Country("im", "Isle of Man"),
        Country("il", "Israel", netflix=True),
        Country("it", "Italy", netflix=True),
        Country("jm", "Jamaica"),
        Country("jp", "Japan", netflix=True),
        Country("je", "Jersey"),
        Country("jo", "Jordan"),
        Country("kz", "Kazakhstan"),
        Country("ke", "Kenya"),
        Country("ki", "Kiribati"),
        Country("kp", "Korea (the Democratic People's Republic of)"),
        Country("kr", "Korea (the Republic of)", netflix=True),
        Country("kw", "Kuwait"),
        Country("kg", "Kyrgyzstan"),
        Country("la", "Lao People's Democratic Republic (the)"),
        Country("lv", "Latvia", netflix=True),
        Country("lb", "Lebanon"),
        Country("ls", "Lesotho"),
        Country("lr", "Liberia"),
        Country("ly", "Libya"),
        Country("li", "Liechtenstein"),
        Country("lt", "Lithuania"),
        Country("lu", "Luxembourg", netflix=True),
        Country("mo", "Macao"),
        Country("mg", "Madagascar"),
        Country("mw", "Malawi"),
        Country("my", "Malaysia", netflix=True),
        Country("mv", "Maldives"),
        Country("ml", "Mali"),
        Country("mt", "Malta"),
        Country("mh", "Marshall Islands (the)"),
        Country("mq", "Martinique"),
        Country("mr", "Mauritania"),
        Country("mu", "Mauritius"),
        Country("yt", "Mayotte"),
        Country("mx", "Mexico", netflix=True),
        Country("fm", "Micronesia (Federated States of)"),
        Country("md", "Moldova (the Republic of)", netflix=True),
        Country("mc", "Monaco"),
        Country("mn", "Mongolia"),
        Country("me", "Montenegro"),
        Country("ms", "Montserrat"),
        Country("ma", "Morocco"),
        Country("mz", "Mozambique"),
        Country("mm", "Myanmar"),
        Country("na", "Namibia"),
        Country("nr", "Nauru"),
        Country("np", "Nepal"),
        Country("nl", "Netherlands (the)", netflix=True),
        Country("nc", "New Caledonia"),
        Country("nz", "New Zealand", netflix=True),
        Country("ni", "Nicaragua"),
        Country("ne", "Niger (the)"),
        Country("ng", "Nigeria"),
        Country("nu", "Niue"),
        Country("nf", "Norfolk Island"),
        Country("mp", "Northern Mariana Islands (the)"),
        Country("no", "Norway", netflix=True),
        Country("om", "Oman"),
        Country("pk", "Pakistan"),
        Country("pw", "Palau"),
        Country("ps", "Palestine, State of"),
        Country("pa", "Panama"),
        Country("pg", "Papua New Guinea"),
        Country("py", "Paraguay"),
        Country("pe", "Peru"),
        Country("ph", "Philippines (the)"),
        Country("pn", "Pitcairn"),
        Country("pl", "Poland", netflix=True),
        Country("pt", "Portugal", netflix=True),
        Country("pr", "Puerto Rico"),
        Country("qa", "Qatar"),
        Country("mk", "Republic of North Macedonia", netflix=True),
        Country("ro", "Romania", netflix=True),
        Country("ru", "Russian Federation (the)"),
        Country("rw", "Rwanda"),
        Country("re", "Réunion"),
        Country("bl", "Saint Barthélemy"),
        Country("sh", "Saint Helena, Ascension and Tristan da Cunha"),
        Country("kn", "Saint Kitts and Nevis"),
        Country("lc", "Saint Lucia"),
        Country("mf", "Saint Martin (French part)"),
        Country("pm", "Saint Pierre and Miquelon"),
        Country("vc", "Saint Vincent and the Grenadines"),
        Country("ws", "Samoa"),
        Country("sm", "San Marino"),
        Country("st", "Sao Tome and Principe"),
        Country("sa", "Saudi Arabia"),
        Country("sn", "Senegal"),
        Country("rs", "Serbia", netflix=True),
        Country("sc", "Seychelles"),
        Country("sl", "Sierra Leone"),
        Country("sg", "Singapore", netflix=True),
        Country("sx", "Sint Maarten (Dutch part)"),
        Country("sk", "Slovakia", netflix=True),
        Country("si", "Slovenia", netflix=True),
        Country("sb", "Solomon Islands"),
        Country("so", "Somalia"),
        Country("za", "South Africa", netflix=True),
        Country("gs", "South Georgia and the South Sandwich Islands"),
        Country("ss", "South Sudan"),
        Country("es", "Spain", netflix=True),
        Country("lk", "Sri Lanka"),
        Country("sd", "Sudan (the)"),
        Country("sr", "Suriname"),
        Country("sj", "Svalbard and Jan Mayen"),
        Country("se", "Sweden", netflix=True),
        Country("ch", "Switzerland", netflix=True),
        Country("sy", "Syrian Arab Republic"),
        Country("tw", "Taiwan (Province of China)", netflix=True),
        Country("tj", "Tajikistan"),
        Country("tz", "Tanzania, United Republic of"),
        Country("th", "Thailand", netflix=True),
        Country("tl", "Timor-Leste"),
        Country("tg", "Togo"),
        Country("tk", "Tokelau"),
        Country("to", "Tonga"),
        Country("tt", "Trinidad and Tobago"),
        Country("tn", "Tunisia"),
        Country("tr", "Turkey", netflix=True),
        Country("tm", "Turkmenistan"),
        Country("tc", "Turks and Caicos Islands (the)"),
        Country("tv", "Tuvalu"),
        Country("ug", "Uganda"),
        Country("ua", "Ukraine", netflix=True),
        Country("ae", "United Arab Emirates (the)", netflix=True),
        Country(
            "gb",
            "United Kingdom of Great Britain and Northern Ireland (the)",
            netflix=True,
        ),
        Country("um", "United States Minor Outlying Islands (the)"),
        Country("us", "United States of America (the)", netflix=True),
        Country("uy", "Uruguay"),
        Country("uz", "Uzbekistan"),
        Country("vu", "Vanuatu"),
        Country("ve", "Venezuela (Bolivarian Republic of)"),
        Country("vn", "Viet Nam", netflix=True),
        Country("vg", "Virgin Islands (British)"),
        Country("vi", "Virgin Islands (U.S.)"),
        Country("wf", "Wallis and Futuna"),
        Country("eh", "Western Sahara"),
        Country("ye", "Yemen"),
        Country("zm", "Zambia"),
        Country("zw", "Zimbabwe"),
        Country("ax", "Åland Islands"),
    ]

    filter = ["fzf", "-0", "-1", "--cycle", "--ansi", "--height", "60%"]

    @classmethod
    def list(cls, filter: str = "", all: bool = False) -> tuple[Country]:
        if all:
            return tuple(c for c in cls._all if c.match(filter))
        else:
            return tuple(c for c in cls._all if c.match(filter) and c.netflix)


class Vpn:
    def __init__(self, src):
        self._src = src

    def get_config(self, filter):
        with scandir(self._src) as files:
            configs = "\n".join(
                sorted(file.name for file in files if file.name.endswith(".ovpn"))
            )
            config = run(filter, input=configs, stdout=PIPE, text=True)
            config = self._src + "/" + config.stdout.rstrip()
        return config

    def launch(self, config, auth):
        execlp(
            "sudo",
            "sudo",
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


if __name__ == "__main__":
    # TODO: fix + add to other scripts
    # if args.codes and not args.list:
    #     parser.error("--codes requires --list")

    if args.list:
        if args.list == 1:
            for c in Countries().list(all=args.all):
                print(c.info if args.codes else c.name)
        elif args.list:
            for c in Countries().list(filter=args.list, all=args.all):
                print(c.info if args.codes else c.name)
        exit()

    if args.download:
        execlp("wget", "wget", download_url)

    if args.pattern:
        countries = Countries().list(args.pattern)

        if args.pattern in ("uk", "gb"):
            code = "uk"
        # unknown country code
        elif not any(args.pattern == c.code for c in countries):
            countries = "\n".join(c.info for c in countries)
            code = run(Countries.filter, input=countries, stdout=PIPE, text=True)
            code = code.stdout.rstrip().split(" -> ")[0]
            code = code.lower().replace("gb", "uk")
        else:
            code = args.pattern

        Countries.filter.extend(("--exact", "-q", code))

    # Main
    vpn = Vpn(src=f"{args.source.rstrip('/')}/ovpn_{args.protocol}")

    if args.config:
        config = args.config
    else:
        config = vpn.get_config(Countries.filter)

    vpn.launch(config, args.credentials)
