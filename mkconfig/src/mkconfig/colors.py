"""Color printing"""

import sys


# foreground, 4-bit
res = '\033[0m'
bld = '\033[1m'
dim = '\033[2m'
ita = '\033[3m'
dir = '\033[38;5;69m'  # 8-bit
bla = '\033[30m'
red = '\033[91m'  # Using bred as it renders better in the terminal; the actual code for red is: \033[31m
grn = '\033[32m'
yel = '\033[33m'
blu = '\033[34m'
mgn = '\033[35m'
cya = '\033[36m'
bred = '\033[91m'
bgrn = '\033[92m'
byel = '\033[93m'
bblu = '\033[94m'
bmgn = '\033[95m'
bcya = '\033[96m'

# background, 4-bit
grn_bg = '\033[42m'
yel_bg = '\033[43m'
red_bg = '\033[101m'  # bred bg


# STDOUT
def print_dim(*args, **kwargs):
    print(dim, end='')
    print(*args, res, **kwargs)


def info(debug: bool, *args, **kwargs):
    if debug:
        print(cya, end='')
        print(*args, res, **kwargs)


# STDERR
def warn(*args, **kwargs):
    print(cya, file=sys.stderr, end='')
    print(*args, res, file=sys.stderr, **kwargs)


def err(*args, **kwargs):
    print(red, file=sys.stderr, end='')
    print(*args, res, file=sys.stderr, **kwargs)


def abort(*args, **kwargs):
    err(*args, **kwargs)
    exit(1)
