#!/usr/bin/env python
#
# Generate Tarantool database to contain feed/filter/limit/cap data
# for a randomized workload.
#
import os
import sys
import time
import random
import datetime

output_fname_db = 'db.lua'
output_fname_wl = 'wl.lua'
request = "box.insert('lists', '{0}', '{1}', {2});\n"

def init_filters():
    seed = time.mktime((datetime.datetime.now().timetuple()))
    print("Generating with seed {0}".format(seed))
    random.seed(seed)

    filters_dir = [
        ('cities.txt', 'city'),
        ('countries.txt', 'country'),
        ('keywords.txt', 'keyword'),
        ('referers.txt', 'referer'),
        ('regions.txt', 'region')
    ]

    print("Filters found: ")
    filters = {}

    for k in filters_dir:
        name = k[1]
        filters[name] = (open('db/'+k[0]).read().split('\n'))
        filters[name].remove('')
        random.shuffle(filters[name])
        print "    '{0}' - {1}".format(name, len(filters[name]))

    feeds = sorted(open('db/feeds.txt').read().split('\n'))
    feeds.remove('')
    return (feeds, filters)

def gauss(len_list=None):
    while True:
        rg = random.gauss(0.5, 0.6) / 2
        if (rg > 0 and rg < 1):
            if len_list is None:
                return rg
            return int(rg * len_list)

def generate_DB(feeds, filters, emitter):
    def select_list_filters(flist, num, used):
        tmp = len(used)
        for i in xrange(num):
            used.add(repr(flist[gauss(len(flist))]))
        return (used, num - (len(used) - tmp))

    print "Generating Database"
    _time = None
    print('0. _____')
    for num, _feed in enumerate(feeds):
        if not (_time is None):
            print "Cycle: {0} sec".format(str(time.clock() - _time))
            print ""
        _time = time.clock()
        print _feed
        sys.stdout.write(str(num + 1) + '. ')
        sys.stdout.flush()
        for _name, _filter in filters.iteritems():
            a, b = (set(), int(random.uniform(0, len(_filter))))
            precision, _try = (b/50, 0)
            while b > precision and _try < 10:
                a, b = select_list_filters(_filter, b, a)
                _try += 1
            sys.stdout.write('X')
            sys.stdout.flush()
            emitter(_feed, _name, a)
        sys.stdout.write('\n')
    print "Cycle: {0} sec".format(str(time.clock() - _time))
    print ""

def generate_WL(feeds, filters, number, emitter):
    def select_tuple_filters(_filters):
        return [repr(v[gauss(len(v))]) for k, v in _filters.iteritems()]

    print "Generating Workload"
    _time = time.clock()
    for i in xrange(number):
        emitter(feeds[gauss(len(feeds))], select_tuple_filters(filters))
    print "Done!"
    print "Cycle: {0} sec".format(str(time.clock() - _time))
    print ""

class Emitter_DB_TNT:
    def __init__(self, fname, sname):
        self.fwl = open(fname, 'w')
        self.sname = sname
        self.request = "box.insert('{0}', '{1}', '{2}', {3});\n"
    def __call__(self, feed, ftype, values):
        self.fwl.write(self.request.format(self.sname, feed, ftype, ', '.join(values)))
    def __del__(self):
        self.fwl.close()

class Emitter_WL_TNT:
    def __init__(self, fname, sname):
        self.fwl = open(fname, 'w')
        self.sname = sname
        self.request = "box.insert('{0}', '{1}', {2});\n"
    def __call__(self, feed, values):
        self.fwl.write(self.request.format(self.sname, feed, ', '.join(values)))
    def __del__(self):
        self.fwl.close()

if __name__ == '__main__':
    _time = time.clock()
    print('=' * 30)
    feeds, filters = init_filters()
    print ""
    print "Cycle: {0} sec".format(str(time.clock() - _time))
    print ""
    print('-' * 30)
    generate_DB(feeds, filters, Emitter_DB_TNT(output_fname_db, 'lists'))
    print('-' * 30)
    generate_WL(feeds, filters, 100000, Emitter_WL_TNT(output_fname_wl, 'workload'))
    print('-' * 30)
    print "Overall time: {0} sec".format(str(time.clock() - _time))
