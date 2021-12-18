#! /usr/bin/env python3

import re

'''Load average'''

class fg:
   BOLD   = '\033[1m'
   ITALIC = '\033[3m'
   RESET  = '\033[0m'
   GREEN  = '\033[32m'
   RED    = '\033[31m'

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
load = [ (fg.GREEN if count > float(l) else fg.RED) + l + fg.RESET for l in load ]

print('   1,    5,   15 :', fg.ITALIC + 'minutes' + fg.RESET)
print(', '.join(load), ':', fg.BOLD + str(count) + fg.RESET, cores,
      fg.ITALIC + 'load average', trend + fg.RESET)
