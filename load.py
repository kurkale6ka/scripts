#! /usr/bin/env python3

'''Load average'''

import re

# load average
with open('/proc/loadavg') as file:
   load = file.read().split() [:3]

one, five, fifteen = map(float, load)

trend = ''
if one > five or one > fifteen:
   trend = '(increasing)'

# get cores count
with open('/proc/cpuinfo') as file:
   count = re.findall(r'^processor\s*:\s*\d', file.read(), re.MULTILINE)
   count = len(count)

cores = 'cores' if count > 1 else 'core'

# Output
print('   1,    5,   15 : minutes')
print(', '.join(load), ':', count, cores, 'load average', trend)
