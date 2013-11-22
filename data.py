#!/usr/bin/env python
#
# Generate Tarantool database to contain feed/filter/limit/cap data
# for a randomized workload.
#
#
import random
import datetime
import time
from lib import feed

seed = time.mktime((datetime.datetime.now().timetuple()))
print("Generating with seed {0}".format(seed))
random.seed(seed)

