# from helpers import *
'''Helpers for interactive python 3 sessions

ls() ~> dir()
 p() -> print()
 h() -> help()
'''

# aliases
h = help
p = print

# dir() without __...__ or _...
def ls(obj, width=15, lines=12):

   '''List dir() entries in rows,
   omitting __...__ or _... entries'''

   rows = []
   lst = [d for d in dir(obj) if not d.startswith('_')]
   length = len(lst)

   if lines > length:
      lines = length + 1

   # Divide list in rows of equal size
   for i in range(0, length, lines):

      row = lst[i:i+lines] # one part
      size = len(row)

      if size < lines:
         row.extend([''] * (lines - size))
      rows.append(row)

   # Output in formatted columns
   for columns in zip(*rows):
      fmt = ('{:' + str(width) + '}') * len(columns)
      print(fmt.format(*columns))
