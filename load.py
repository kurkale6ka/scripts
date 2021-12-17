#! /usr/bin/env python3

'''Load average'''

import re

# load average
with open('/proc/loadavg') as file:
   load = file.read().split() [:3]

one, five, fifteen = map(float, load)
msg = None

if one > five or one > fifteen:
   msg = 'increasing'

# get cores count
with open('/proc/cpuinfo') as file:
   cores = re.findall(r'^processor\s*:\s*\d', file.read(), re.MULTILINE)

# Output
print('   1,    5,   15 : minutes')
print(', '.join(load), ':', len(cores), 'cores load average', end='')

if msg:
   print(f' ({msg})') # trend
