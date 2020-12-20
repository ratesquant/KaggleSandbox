# -*- coding: utf-8 -*-
"""
Created on Sat Dec 19 19:46:59 2020

@author: chirokov
"""
    
from kaggle_environments import evaluate, make, utils
from kaggle_environments.utils import structify

from time import time
import numpy as np
from random import choice

env = make("connectx", debug=True)
#env.render()

#board = obs.board
env.reset()
config = env.configuration    

columns = config.columns
rows = config.rows
size = rows * columns  
inarow = config.inarow - 1        

column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            

def get_move_row(board, column):            
    for r in range(rows-1, 0, -1):
        if board[column + (r * columns)] == 0:
            return r
    return 0  
    
def is_win(board, row, column, mark):
    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                return i - 1
        return inarow
    
    result = (
        count(1, 0) >= inarow  # vertical.
        or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
        or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
        or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
    )
    return result

def is_win_v2(board, row, column, mark):
    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                return i - 1
        return inarow
    
    def count_10(offset): #1, 0
        steps = min(rows - row - 1, inarow)
        index =offset 
        for i in range(1, steps + 1): 
            index += columns
            if board[index] != mark:
                return i - 1
        return steps    
    
    def count_01(offset): #0, 1  
        steps = min(columns - column - 1, inarow)      
        for i in range(1, steps + 1):            
            if board[offset + i] != mark:
                return i - 1
        return steps    
    
    def count_02(offset): #0, -1
        steps = min(column, inarow)        
        for i in range(1, steps + 1):
            if board[offset - i] != mark:
                return i - 1
        return steps  
    
    def count_22(offset):
        steps = min(column, row, inarow) 
        index = offset
        for i in range(1, steps + 1):
            index -= (columns + 1)
            if board[index] != mark:
                return i - 1
        return steps
    
    def count_11(offset):
        steps = min(columns - column - 1, rows - row - 1, inarow)          
        index = offset
        for i in range(1, steps + 1):            
            index = index + columns + 1
            if board[index] != mark:
                return i - 1
        return steps
    
    def count_21(offset):
        steps = min(columns - column - 1, row, inarow)   
        index = offset
        for i in range(1, steps + 1):            
            index = index - columns + 1
            if board[index] != mark:
                return i - 1
        return steps
    
    def count_12(offset):
        steps = min(column, rows - row - 1, inarow)   
        index = offset
        for i in range(1, steps + 1):            
            index = index + columns - 1
            if board[index] != mark:
                return i - 1
        return steps   
   
    offset = column + row * columns
    result = (
        count_10(offset) >= inarow  # vertical.
        or (count_01(offset) + count_02(offset)) >= inarow  # horizontal.
        or (count_22(offset) + count_11(offset)) >= inarow  # top left diagonal.
        or (count_21(offset) + count_12(offset)) >= inarow  # top right diagonal.
    )
    return result


def check_position(board, mark):
    for column in column_order:        
        if board[column] == 0 and is_win(board, get_move_row(board, column) , column, mark):
            return True
    return False

def play_moves(moves, board):    
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 1 if mark == 2 else 2
    return mark

TEST_CASES_FOLDER = 'D:/Github/KaggleSandbox/connect_x/positions'
    
def read_tests(filename):
    with open(filename, "r") as f:
        lines = f.readlines()
    return [(t.split()[0], int(t.split()[1])) for t in lines]

tests1 = read_tests(TEST_CASES_FOLDER + '/Test_L3_R1') 

def run_tests(tests):
    total_evals = 0
    error_count = 0 
    elapsed = [0.0] * len(tests)
    for i, t in enumerate(tests):
        #i, t = 0, tests[0]
        mark = 1
        moves =t[0]        
        board = columns * rows * [0]
        mark = play_moves(moves, board)
        start_time = time()
        for j in range(1000):
            check_position(board, mark)
        elapsed[i] =  time()-start_time
    return elapsed
        
elapsed = run_tests(tests1)
sum(elapsed) #38.56199336051941
#40.67699694633484 - v2

#22.9 µs ± 22.3 ns per loop (mean ± std. dev. of 7 runs, 10000 loops each)
mark = 1
moves =tests1[0][0]        
board = columns * rows * [0]
mark = play_moves(moves, board)
start_time = time()
%timeit check_position(board, mark)