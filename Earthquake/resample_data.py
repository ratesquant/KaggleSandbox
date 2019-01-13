# -*- coding: utf-8 -*-
"""
Created on Sat Jan 12 19:47:51 2019

@author: chirokov
"""

import os

def resample_file(filename_in, filename_out, n = 10):
    with open(filename_in, 'rt') as f_in:
        with open(filename_out, 'wt') as f_out:
            header = f_in.readline()
            f_out.write(header)
            count = 0
            for line in f_in:
                count = count + 1
                if count % n == 0:
                    f_out.write(line)   

folder_name = 'F:/Github/KaggleSandbox/Earthquake/data'

filename_in  = os.path.join(folder_name, 'train.csv')
filename_out = os.path.join(folder_name, 'train_100.csv')

resample_file(filename_in, filename_out, n = 100)