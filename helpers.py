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
def ls(obj='void', lines=12):

   '''List dir() entries in rows,
   omitting __...__ or _... entries'''

   if obj != 'void':
      dirs = dir(obj)
   else:
      dirs = globals().keys()

   lst = [d for d in dirs if not d.startswith('_')]

   length = len(lst)
   if lines > length:
      lines = length

   rows = []

   # Divide list in rows of equal size
   for i in range(0, length, lines):

      row = lst[i:i+lines] # one part
      size = len(row)

      if size < lines:
         row.extend([''] * (lines - size))
      rows.append(row)

   # Output in formatted columns
   width = max(map(len, lst)) + 2
   for columns in zip(*rows):
      fmt = ('{:' + str(width) + '}') * len(columns)
      print(fmt.format(*columns))
