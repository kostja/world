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

from itertools import imap

output_fname_db = 'data.lua'
output_fname_wl = 'wl.lua'
output_fname_cap = 'cap.lua'

def init_filters():
    seed = time.mktime((datetime.datetime.now().timetuple()))
    print("Generating with seed {0}".format(seed))
    random.seed(seed)

    filters_dir = [
        ('cities.txt', 'city', 0.1),
        ('useragents.txt', 'useragent', 0.5),
        ('countries.txt', 'country', 0.5),
        ('keywords.txt', 'keyword', 0.5),
        ('referers.txt', 'referer', 0.2),
        ('regions.txt', 'region', 0.3)
    ]

    print("Filters found: ")
    filters = {}

    for k in filters_dir:
        name = k[1]
        filters[name] = open('db/'+k[0]).read().split('\n')
        filters[name].remove('')
        random.shuffle(filters[name])
        filters[name] = [filters[name], k[2]]
        print "    '{0}' - {1}".format(name, len(filters[name][0]))

    cap_medians = [k.split(': ') for k in open('db/cap_medians.txt').read().split('\n')]
    cap_medians.remove([''])
    cap_medians = {k[0]: int(k[1]) for k in cap_medians}

    feeds = list(set(sorted(open('db/feeds.txt').read().split('\n'))))[:3]
    feeds.remove('')
    return (feeds, filters, cap_medians)

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
            used.add(flist[gauss(len(flist))])
        return (used, num - (len(used) - tmp))

    print('-' * 30)
    print "Generating Database"
    print('-' * 30)

    _time = None
    for num, _feed in enumerate(feeds):
        if not (_time is None):
            print "Cycle: {0} sec".format(str(time.clock() - _time))
            print ""
        _time = time.clock()
        print _feed
        sys.stdout.write(str(num + 1) + '. ')
        sys.stdout.flush()
        for _name, _filter in filters.iteritems():
            a, b = (set(), int(random.uniform(0, len(_filter[0]))*_filter[1]))
            precision, _try = (b/50, 0)
            while b > precision and _try < 10:
                a, b = select_list_filters(_filter[0], b, a)
                _try += 1
            sys.stdout.write('X')
            sys.stdout.flush()
            emitter(_feed, _name, a)
        sys.stdout.write('\n')
    print "Cycle: {0} sec".format(str(time.clock() - _time))

def generate_WL(feeds, filters, number, emitter):
    def select_tuple_filters(_filters):
        return [v[0][gauss(len(v[0]))] for k, v in _filters.iteritems()]

    print('-' * 30)
    print "Generating Workload"
    print('-' * 30)
    _time = time.clock()
    for i in xrange(number):
        emitter(select_tuple_filters(filters))
    print "Done!"
    print "Cycle: {0} sec".format(str(time.clock() - _time))

def generate_CAP(feeds, caps, emitter):
    print('-' * 30)
    print "Generating CAP"
    print('-' * 30)
    _time = time.clock()
    slist = ['second', 'hour', 'day']
    print "CAPs:"
    for _cap in slist:
        print "    {0} : {1}".format(_cap, caps[_cap])
    for _feed in feeds:
        emitter(_feed, [gauss(2*caps[k]) for k in slist])
    print "Done!"
    print "Cycle: {0} sec".format(str(time.clock() - _time))


class Emitter_CAP_TNT:
    def __init__(self, fname):
        self.fwl = open(fname, 'w')
        self.request_s = "box.insert('feed_search_cap_second', '{0}', box.time(), 0, {1});\n"
        self.request_h = "box.insert('feed_search_cap_hour', '{0}', box.time(), 0, {1});\n"
        self.request_d = "box.insert('feed_search_cap_day', '{0}', box.time(), 0, {1});\n"
    def __call__(self, feed, value):
        self.fwl.write(self.request_s.format(feed, repr(value[0])))
        self.fwl.write(self.request_h.format(feed, repr(value[1])))
        self.fwl.write(self.request_d.format(feed, repr(value[2])))
    def __del__(self):
        self.fwl.close()


class Emitter_DB_TNT:
    def __init__(self, fname, sname):
        self.fwl = open(fname, 'w')
        self.sname = sname
        self.request = "box.space['{0}']:insert('{1}', '{2}', {3})\n"
    def __call__(self, feed, ftype, values):
        for v in values:
            self.fwl.write(self.request.format(self.sname, feed, ftype, repr(v)))
    def __del__(self):
        self.fwl.close()

class Emitter_WL_TNT:
    def __init__(self, fname, sname):
        self.fwl = open(fname, 'w')
        self.sname = sname
        self.request = "box.space['{0}']:auto_increment({1})\n"
    def __call__(self, values):
        self.fwl.write(self.request.format(self.sname, ", ".join(imap(repr, values))))
    def __del__(self):
        self.fwl.close()

if __name__ == '__main__':
    _time = time.clock()
    print('=' * 30)
    feeds, filters, cap = init_filters()
    print ""
    print "Cycle: {0} sec".format(str(time.clock() - _time))
    generate_DB(feeds, filters, Emitter_DB_TNT(output_fname_db, 'blacklists'))
    generate_WL(feeds, filters, 100000, Emitter_WL_TNT(output_fname_wl, 'workload'))
    generate_CAP(feeds, cap, Emitter_CAP_TNT(output_fname_cap))
    print('-' * 30)
    print "Overall time: {0} sec".format(str(time.clock() - _time))
