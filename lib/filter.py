import random

class Filter(object):
    def __init__(filename):
        self.values = []
        with open(filename, "r") as f:
            for value in f:
                self.values.append(value.rstrip('\n'))
    def value():
        while true: 
            index = random.normal(0.5, 0.4) * len(self.values)
            if index >= 0 and index < len(self.values):
                break
        return self.values[index]
