# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""
import os

filename = 'W:/loan_level/fnma/raw/2003Q3.csv'
max_lines = int(1e7)

os.path.exists(filename)

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
