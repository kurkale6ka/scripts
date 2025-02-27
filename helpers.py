"""Helpers for interactive python3 sessions

ls() ~> dir()
 p() -> print()
 h() -> help()
"""

from itertools import zip_longest

# aliases
h = help
p = print


# ls()
# similar to dir() without __...__ or _...
def ls(obj=None, screen_lines: int | None = None):
    """List dir() entries in sorted columns,
    omitting __...__ or _... entries

    :obj:
        same as dir() + 'b(uiltins)'
        e.g. ls(''.split), ls([])

    :screen_lines:
        number of rows. more rows => less columns
    """

    # build the list from dir()
    if obj in ['builtins', 'b']:
        dirs = [d for d in dir(__builtins__) if d.islower()]
    elif obj is not None:
        dirs = dir(obj)
    else:
        dirs = sorted(globals())

    lst = [d for d in dirs if not d.startswith('_')]

    # Setup the display grid
    length = len(lst)
    min_lines = 7

    if length < min_lines:
        lines = length or 1
    else:
        # aim for 4 columns..
        lines = length // 4
        # ..but reduce (upping lines) if lines < min_lines
        if lines < min_lines and length >= min_lines:
            lines = min_lines

    # overwrite
    if screen_lines:
        if screen_lines <= length:
            lines = screen_lines
        else:
            lines = length

    # Divide the list in rows of equal size
    rows = []
    for i in range(0, length, lines):
        rows.append(lst[i : i + lines])  # one part

    # Output in formatted columns
    width = max(map(len, lst), default=1) + 2
    for columns in zip_longest(*rows, fillvalue=''):
        fmt = ('{:' + str(width) + '}') * (len(columns) - 1)
        fmt += '{}'
        print(fmt.format(*columns))
