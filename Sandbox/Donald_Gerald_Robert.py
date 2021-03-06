# -*- coding: utf-8 -*-
import random

chars = set(['D', 'O', 'N', 'A', 'L', 'G', 'E', 'R', 'B', 'T'])
numerals = list(range(10))

def encode(word, lut):
    return int(''.join([str(lut[c]) for c in word]))    

while True:
    random.shuffle(numerals)
    lut = dict(zip(chars, numerals))   
    c1 = encode('DONALD', lut)     
    c2 = encode('GERALD', lut)     
    c3 = encode('ROBERT', lut)   
    if c1 + c2 ==  c3:
        print(lut)
        print('%s + %s = %s' % (c1, c2, c3)) #526485 + 197485 = 723970
        break;
