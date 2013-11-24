#!/usr/bin/env python
import os
import sys
import datetime

feeds = sorted(open('db/feeds.txt').read().split('\n'))
feeds.remove('')


sys.stdout.write("if box.space['feeds'] == nil then\n")
sys.stdout.write("    box.schema.create_space('feeds')\n")
sys.stdout.write('    box.space[\'feeds\']:create_index(\'primary\', \'tree\', { parts = { 0, \'str\'}})\n')
sys.stdout.write("end\n")
for _feed in feeds:
    sys.stdout.write("box.space['feeds']:replace('{0}')\n".format(_feed))
