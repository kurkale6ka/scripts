#! /usr/bin/env python3

desc = '''Wrapper around the cal (gcal, ncal, cal) UNIX commands
aiming to standardise output and available options

    output:
    * always start weeks on Monday
    * always display days horizontally

    options: always provide -3/-y
'''

from os import execlp
from shutil import which
import argparse

parser = argparse.ArgumentParser(prog='cal', description=desc, formatter_class=argparse.RawDescriptionHelpFormatter, add_help=False)

parser.add_argument("-h", "--help",  action="store_true", help="show own help + \"cal\"'s one")
parser.add_argument("-3", "--three", action="store_true", help="three months display")
parser.add_argument("-y", "--year",  action="store_true", help="whole year display")

# Store own args as argparse.Namespace and the rest as list
own_args, args = parser.parse_known_args()

# check if command is in PATH
def cmd(exe):
    return which(exe) is not None

if cmd('gcal'):

    # -s, --starting-day 1 (Monday)
    cal = ['gcal', '-s1']

    if own_args.three:
        # previous, actual and next month: month mode commands
        cal.append('.')
    elif own_args.year:
        # -b, --blocks: displays 4 blocks with 3 months at a time (4x3 = 12)
        cal.append('-b4')

elif cmd('ncal'):

    # -M Monday, -b oldstyle format: horizontal
    cal = ['ncal', '-Mb']

    # needed as we shadow ncal's ones
    if own_args.three:
        cal.append('-3')
    elif own_args.year:
        cal.append('-y')

elif cmd('cal'):

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

if __name__  == "__main__":

    # show own help + "cal"'s one
    if own_args.help:
        parser.print_help()
        print('\n', '-' * 54, '\n', sep='')
        execlp(cal[0], cal[0], '--help')

    # launch "cal"
    execlp(cal[0], *cal)
