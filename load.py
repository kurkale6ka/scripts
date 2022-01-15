#! /usr/bin/env python3

'''Load average with clear time slices and trend'''

from os import cpu_count

esc = '\033['
GREEN, RED, BOLD, ITALIC, RESET = [f'{esc}{code}m' for code in (32, 31, 1, 3, 0)]

# load average
with open('/proc/loadavg') as file:
   load = file.read().split() [:3]

one, five, fifteen = map(float, load)

trend = ''
if one > five or one > fifteen:
   trend = '(increasing)'

# get cores count
count = cpu_count()
cores = 'cores' if count > 1 else 'core'

# Output
load = [ (GREEN if count > float(ld) else RED) + ld + RESET for ld in load ]

print('   1,    5,   15 :', ITALIC + 'minutes' + RESET)
print(', '.join(load), ':', BOLD + str(count) + RESET, cores,
      ITALIC + 'load average', trend + RESET)
