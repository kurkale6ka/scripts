#! /usr/bin/env python3

# sudoku easy solutions

puzzle = {}
y = 0

# open a puzzle
with open('sud1', 'r') as file:
    for line in file:
        y += 1
        x = 0
        for c in line:
            if c in '-123456789':
                x += 1
                if c == '-':
                    puzzle[(x, y)] = c
                else:
                    puzzle[(x, y)] = int(c)


# pretty puzzle print
def ppuzzle(puzzle):
    for i in range(1, 10):
        for j in range(1, 10):
            print('{} '.format(str(puzzle[(j, i)])), end='')
            if j == 9:
                print()


def square_start(num):
    if num % 3 == 1:
        return num
    elif num % 3 == 2:
        return num - 1
    else:
        return num - 2


puzzle2 = {}


def easy_solutions():
    for x, y in puzzle:
        if puzzle[(x, y)] == '-':
            # exclude numbers in the same col/row/sqr
            col = {puzzle[(x, j)] for j in range(1, 10)}
            row = {puzzle[(a, y)] for a in range(1, 10)}

            sx = square_start(x)
            sy = square_start(y)
            sqr = {puzzle[(i, j)] for i in range(sx, sx + 3) for j in range(sy, sy + 3)}

            # possible numbers
            values = {n for n in range(1, 10) if n not in col | row | sqr}

            # easy solutions
            if len(values) == 1:
                puzzle2[(x, y)] = values.pop()

    puzzle.update(puzzle2)


# print input
ppuzzle(puzzle)

while True:
    unknowns = len([x for x in puzzle.values() if x == '-'])
    easy_solutions()
    if len([x for x in puzzle.values() if x == '-']) == unknowns:
        break

# print solution
print()
ppuzzle(puzzle)
