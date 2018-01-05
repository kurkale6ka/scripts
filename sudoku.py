# sudoku easy solutions

puzzle = {}

y = 0

with open('sud1', 'r') as file:
   for line in file:
      y += 1
      x = 0
      for c in line:
         if c in "-123456789":
            x += 1
            if c == "-":
               puzzle[(x,y)] = c
            else:
               puzzle[(x,y)] = int(c)

#   x 1  2  3  4  5  6  7  8  9         x 1  2  3  4  5  6  7  8  9
# y +--------------------------       y +--------------------------
# 1 | -  2  6  -  -  -  8  1  -       1 | 7  2  6  4  9  3  8  1  5
# 2 | 3  -  -  7  -  8  -  -  6       2 | 3  1  5  7  2  8  9  4  6
# 3 | 4  -  -  -  5  -  -  -  7       3 | 4  8  9  6  5  1  2  3  7
# 4 | -  5  -  1  -  7  -  9  -  ==>  4 | 8  5  2  1  4  7  6  9  3
# 5 | -  -  3  9  -  5  1  -  -       5 | 6  7  3  9  8  5  1  2  4
# 6 | -  4  -  3  -  2  -  5  -       6 | 9  4  1  3  6  2  7  5  8
# 7 | 1  -  -  -  3  -  -  -  2       7 | 1  9  4  8  3  6  5  7  2
# 8 | 5  -  -  2  -  4  -  -  9       8 | 5  6  7  2  1  4  3  8  9
# 9 | -  3  8  -  -  -  4  6  -       9 | 2  3  8  5  7  9  4  6  1

def easy_solutions():

   for (x,y) in puzzle:

      if puzzle[(x,y)] == "-":

         # exclude numbers in the same col/row/sqr
         col = { puzzle[(x,j)] for j in range(1,10) }
         row = { puzzle[(a,y)] for a in range(1,10) }
         sqr = { puzzle[(i,j)] for i in range(x-1, x+2) for j in range(y-1, y+2) if puzzle.has_key((i,j)) }

         # possible numbers
         values = { n for n in range(1,10) if n not in col | row | sqr }

         # easy solutions
         if len(values) == 1:
            print((x,y))
            print(values)
            puzzle[(x,y)] = values.pop()

easy_solutions()
