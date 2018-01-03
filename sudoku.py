# sudoku easy solutions

#   x 1  2  3  4  5  6  7  8  9
# y +--------------------------
# 1 | -  2  6  -  -  -  8  1  -
# 2 | 3  -  -  7  -  8  -  -  6
# 3 | 4  -  -  -  5  -  -  -  7
# 4 | -  5  -  1  -  7  -  9  -
# 5 | -  -  3  9  -  5  1  -  -
# 6 | -  4  -  3  -  2  -  5  -
# 7 | 1  -  -  -  3  -  -  -  2
# 8 | 5  -  -  2  -  4  -  -  9
# 9 | -  3  8  -  -  -  4  6  -

#   x 1  2  3  4  5  6  7  8  9
# y +--------------------------
# 1 | 7  2  6  4  9  3  8  1  5
# 2 | 3  1  5  7  2  8  9  4  6
# 3 | 4  8  9  6  5  1  2  3  7
# 4 | 8  5  2  1  4  7  6  9  3
# 5 | 6  7  3  9  8  5  1  2  4
# 6 | 9  4  1  3  6  2  7  5  8
# 7 | 1  9  4  8  3  6  5  7  2
# 8 | 5  6  7  2  1  4  3  8  9
# 9 | 2  3  8  5  7  9  4  6  1

puzzle = {
(1, 1): "-", (2, 1):   2, (3, 1):   6, (4, 1): "-", (5, 1): "-", (6, 1): "-", (7, 1):   8, (8, 1):   1, (9, 1): "-",
(1, 2):   3, (2, 2): "-", (3, 2): "-", (4, 2):   7, (5, 2): "-", (6, 2):   8, (7, 2): "-", (8, 2): "-", (9, 2):   6,
(1, 3):   4, (2, 3): "-", (3, 3): "-", (4, 3): "-", (5, 3):   5, (6, 3): "-", (7, 3): "-", (8, 3): "-", (9, 3):   7,
(1, 4): "-", (2, 4):   5, (3, 4): "-", (4, 4):   1, (5, 4): "-", (6, 4):   7, (7, 4): "-", (8, 4):   9, (9, 4): "-",
(1, 5): "-", (2, 5): "-", (3, 5):   3, (4, 5):   9, (5, 5): "-", (6, 5):   5, (7, 5):   1, (8, 5): "-", (9, 5): "-",
(1, 6): "-", (2, 6):   4, (3, 6): "-", (4, 6):   3, (5, 6): "-", (6, 6):   2, (7, 6): "-", (8, 6):   5, (9, 6): "-",
(1, 7):   1, (2, 7): "-", (3, 7): "-", (4, 7): "-", (5, 7):   3, (6, 7): "-", (7, 7): "-", (8, 7): "-", (9, 7):   2,
(1, 8):   5, (2, 8): "-", (3, 8): "-", (4, 8):   2, (5, 8): "-", (6, 8):   4, (7, 8): "-", (8, 8): "-", (9, 8):   9,
(1, 9): "-", (2, 9):   3, (3, 9):   8, (4, 9): "-", (5, 9): "-", (6, 9): "-", (7, 9):   4, (8, 9):   6, (9, 9): "-"
}

for (x,y) in puzzle:

   if puzzle[(x,y)] == "-":

      # exclude numbers in the same col/row/sqr
      col = { puzzle[(x,j)] for j in range(1,10) }
      row = { puzzle[(a,y)] for a in range(1,10) }
      sqr = { puzzle[(i,j)] for i in range(x-1, x+2) for j in range(y-1, y+2) if puzzle.has_key((i,j)) }

      # possible numbers
      values = { n for n in range(1,10) if n not in col.union(row).union(sqr) }

      # easy solutions
      if len(values) == 1:
         print((x,y))
         print(values)
         puzzle[(x,y)] = values.pop()