#! /usr/bin/env python3

"""Wrapper around the cal (gcal, ncal, cal) UNIX commands
aiming to standardise output and available options

output:
    * always start weeks on Monday
    * always display days horizontally

options:
    always provide -3/-y
"""

from argparse import ArgumentParser, RawDescriptionHelpFormatter
from os import execlp
from shutil import which

parser = ArgumentParser(
    prog='cal',
    description=__doc__,
    formatter_class=RawDescriptionHelpFormatter,
    add_help=False,
)

grp_period = parser.add_mutually_exclusive_group()
grp_period.add_argument(
    '-3', '--three', action='store_true', help='three months display'
)
grp_period.add_argument('-y', '--year', action='store_true', help='whole year display')
parser.add_argument(
    '-h',
    '--help',
    action='store_true',
    help='show this help, followed by the resident "cal"\'s one',
)

# Store own args as argparse.Namespace and the rest as list
own_args, args = parser.parse_known_args()


def command(exe: str) -> bool:
    """Check if command is in PATH"""
    return which(exe) is not None


if command('gcal'):
    # -s, --starting-day 1 (Monday)
    cal = ['gcal', '-s1']

    if own_args.three:
        # previous, actual and next month: month mode commands
        cal.append('.')
    elif own_args.year:
        # -b, --blocks: displays 4 blocks with 3 months at a time (4x3 = 12)
        cal.append('-b4')

elif command('ncal'):
    # -M Monday, -b oldstyle format: horizontal
    cal = ['ncal', '-Mb']

    # needed as we shadow ncal's ones
    if own_args.three:
        cal.append('-3')
    elif own_args.year:
        cal.append('-y')

elif command('cal'):
    # UNIX/FreeBSD version of cal:
    # cal -m could fail as support for -m3y was unknown last time I checked

    # -m, --monday
    cal = ['cal', '-m']

    if own_args.three:
        cal.append('-3')
    elif own_args.year:
        cal.append('-y')

else:
    exit('Please install gcal, ncal or cal!')

cal.extend(args)

if __name__ == '__main__':
    if own_args.help:
        # this help
        parser.print_help()
        print()
        print('-' * 67)
        print()

        # resident "cal"'s help
        execlp(cal[0], cal[0], '--help')

    # Show calendar
    execlp(cal[0], *cal)
