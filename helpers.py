# from helpers import *

# aliases
h = help
p = print

# dir() without __...__
def ls(obj, columns=4, width=20):
   '''List dir() entries in columns, omitting __...__'''

   listing = [d for d in dir(obj) if not d.startswith('__')]

   i = 0
   for member in listing:
      fields = listing[i:i+columns]
      count = len(fields)
      if fields:
         fmt = ('{:' + str(width) + '}') * count
         print(fmt.format(*fields))
         i += count
