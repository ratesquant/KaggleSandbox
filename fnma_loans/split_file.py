# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import os
import numpy as np
import random
from math import floor
import glob
from time import time

filename = 'W:/loan_level/fnma/raw/2000Q1.csv'
max_lines = int(1e7)

os.path.exists(filename)

def select_loans(filename_in, filenam_out, sep, id_col, fraction = 0.01):
    start_time = time()
    with open(filename_in, "r") as f_in: 
        ids = set()  
        for line in f_in:
            ids.add(line.split(sep)[id_col].strip() )                          
        ids_sample = set(np.random.choice(list(ids), size=round(fraction*len(ids)), replace=False))
        print('%s ids: %d selected: %d in %.1f sec' % (filename_in, len(ids), len(ids_sample), time()-start_time ))        
    with open(filename_in, "r") as f_in: 
        with open(filenam_out, "w") as f_out: 
            for line in f_in:
                my_id = line.split(sep)[id_col].strip()
                if my_id in ids_sample:
                    f_out.write(line)
    print('saved to %s in %.1f sec' % (filenam_out, time()-start_time ))        

#test on one file
np.random.seed(1234)
select_loans(filename, filename + '.5pct', sep = '|', id_col=1, fraction = 0.05)
     
#os.listdir('W:/loan_level/fnma/raw')  
all_files = glob.glob('W:/loan_level/fnma/raw/*.csv') 

for filename in all_files:
    select_loans(filename, filename + '.2pct', sep = '|', id_col=1, fraction = 0.02)

with open(filename, "r") as f_in:
    line_count = 0
    current_chunk = -1
    chunk_file = None
    for line in f_in:
        chunk_id = line_count // max_lines
        line_count = line_count + 1
        if chunk_id > current_chunk:
            current_chunk = chunk_id
            print('starting new chunk %d' % chunk_id)
            if chunk_file is not None:
                chunk_file.close()
            chunk_file = open('%s_part_%d' % (filename,chunk_id), "w")
        chunk_file.write(line)
    if chunk_file is not None:
        chunk_file.close()      
        
        
        
        
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
