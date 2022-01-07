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
def ls(obj='void', screen_lines=None):

   '''List dir() entries in sorted columns,
   omitting __...__ or _... entries'''

   if obj != 'void':
      dirs = dir(obj)
   else:
      dirs = globals().keys()

   lst = [d for d in dirs if not d.startswith('_')]
   length = len(lst)

   # Setup the display grid
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

   rows = []
   # Divide list in rows of equal size
   for i in range(0, length, lines):
      row = lst[i:i+lines] # one part
      size = len(row)

      if size < lines:
         row.extend([''] * (lines - size))
      rows.append(row)

   # Output in formatted columns
   width = max(map(len, lst), default=1) + 2
   for columns in zip(*rows):
      fmt = ('{:' + str(width) + '}') * len(columns)
      print(fmt.format(*columns))
