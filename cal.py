#! /usr/bin/env python3

'''Wrapper around the cal UNIX command
aiming to standardise output and available options

output:
  * always start weeks on Monday
  * always display days horizontally

options:
  * always provide -3/-y (must be used in 1st position)
'''

# TODO: argparse fro -3, -y, -h for them plus gcal, ncal help

from sys import argv
from os import execlp
from shutil import which

# check if command is in PATH
def cmd(exe):
    return which(exe) is not None

args = argv[1:]

if cmd('gcal'):
    cal = ['gcal', '-s1']

    if args:
        if args[0] == '-3':
            cal.append('.')
            args.pop(0)
        elif args[0] == '-y':
            cal.append('-b4')
            args.pop(0)

elif cmd('ncal'):
    cal = ['ncal', '-Mb']

elif cmd('cal'):
    cal = ['cal', '-m']
    # UNIX/FreeBSD version of cal:
    # cal -m above will fail as support for -m3y was unknown last time I checked

else:
    exit('Please install gcal, ncal or cal!')

cal.extend(args)

if __name__  == "__main__":
    execlp(cal[0], *cal)
