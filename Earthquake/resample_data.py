k# -*- coding: utf-8 -*-
"""
Created on Sat Jan 12 19:47:51 2019

@author: chirokov
"""

import os
import numpy as np

def resample_file(filename_in, filename_out, n = 10):
    with open(filename_in, 'rt') as f_in:
        with open(filename_out, 'wt') as f_out:
            header = f_in.readline()
            f_out.write(header)
            count = 0
            for line in f_in:                
                if count % n == 0:
                    f_out.write(line)   
                count = count + 1
                
def split2chunks(filename_in, folder_name, chunk_starts, chunk_size):
    chunk_filenames = [(os.path.join(folder_name, 'train_chunk_%d.csv' % i), cs, cs+chunk_size) for i, cs in enumerate(chunk_starts) ]
    chunk_files = dict()
    with open(filename_in, 'rt') as f_in:
        header = f_in.readline()        
        for cfile in chunk_filenames:
            chunk_files[cfile[0]] = open(cfile[0], 'wt')
            chunk_files[cfile[0]].write(header)        
        line_count = 0
        for line in f_in:
            for cfile in chunk_filenames:
                if cfile[1]>=line_count and cfile[2]<line_count:
                  chunk_files[cfile[0]].write(line)                  
            line_count = line_count + 1                
        for cfile in chunk_filenames:
            chunk_files[cfile[0]].close()             

folder_name = 'F:/Github/KaggleSandbox/Earthquake/data'

filename_in  = os.path.join(folder_name, 'train.csv')
filename_out = os.path.join(folder_name, 'train_1000.csv')

resample_file(filename_in, filename_out, n = 1000)

#%%  range of sampled values

for sample_freq in [64, 128]:    
    resample_file(filename_in, os.path.join(folder_name, 'train_%d.csv'%sample_freq), n = sample_freq)


#%%  create n samples with up to 150k observations
n_chunks = 100
chunk_size = 150000
total_size = 629145480

chunk_starts = sorted( np.random.randint(0, total_size-chunk_size, size = n_chunks) )

split2chunks(filename_in, folder_name, chunk_starts, chunk_size)
