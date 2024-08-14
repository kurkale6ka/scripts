import sys


class Fg:
    """Color printing"""

    res = "\033[0m"
    bld = "\033[1m"
    dim = "\033[2m"
    red = "\033[31m"
    grn = "\033[32m"
    yel = "\033[33m"
    blu = "\033[34m"
    mgn = "\033[35m"
    cya = "\033[36m"
    bred = "\033[91m"
    bgrn = "\033[92m"
    byel = "\033[93m"
    bblu = "\033[94m"
    bmgn = "\033[95m"
    bcya = "\033[96m"

    @classmethod
    def print_dim(cls, *args, **kwargs):
        print(cls.dim, end="")
        print(*args, cls.res, **kwargs)

    @classmethod
    def print_warn(cls, *args, **kwargs):
        print(cls.yel, file=sys.stderr, end="")
        print(*args, cls.res, file=sys.stderr, **kwargs)

    @classmethod
    def print_err(cls, *args, **kwargs):
        print(cls.bred, file=sys.stderr, end="")
        print(*args, cls.res, file=sys.stderr, **kwargs)

    @classmethod
    def abort(cls, *args, **kwargs):
        cls.print_err(*args, **kwargs)
        exit(1)
