#!/usr/bin/env python
import os
import sys
import datetime

feeds = sorted(open('db/feeds.txt').read().split('\n'))
feeds.remove('')


sys.stdout.write("box.space['feeds']:drop()\n")
sys.stdout.write("box.schema.create_space('feeds')\n")
sys.stdout.write('box.space[\'feeds\']:create_index(\'primary\', \'tree\', { parts = { 0, \'str\'}})\n')
for _feed in feeds:
    sys.stdout.write("box.space['feeds']:insert('{0}')\n".format(_feed))
