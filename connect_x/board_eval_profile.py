# -*- coding: utf-8 -*-
"""
Created on Thu Nov 26 19:05:39 2020

@author: chirokov
"""

#https://github.com/PascalPons/connect4/blob/master/Solver.cpp
    
from kaggle_environments import evaluate, make, utils
from kaggle_environments.utils import structify

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


#%% Eval functions 
def board_eval(board, moves, column, mark):
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
    score =0 
    if column > 0 and board[row * columns + column - 1] == mark:              #left same mark
        score += 1
    if (column < columns - 1 and board[row * columns + column + 1] == mark):  #right same mark
        score += 1        
    if row > 0 and column > 0 and board[(row - 1) * columns + column - 1] == mark:  #lower left - same mark
        score += 1
    if row > 0 and column < columns - 1 and board[(row - 1) * columns + column + 1] == mark: #lower right - same mark
        score += 1           
    return score

def board_eval_ex_fast(board, moves, column, mark):        
    inarow = config.inarow - 1  
    inv_mark = 1 if mark == 2 else 2
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])

    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or c < 0 or r >= rows  or c >= columns or board[c + (r * columns)] == inv_mark):
                return i - 1
        return inarow
    score = 0     
    score += int(count( 1,  0) + count(-1,  0) >= inarow)            
    score += int(count( 0,  1) + count( 0, -1) >= inarow)
    score += int(count(-1, -1) + count( 1,  1) >= inarow)
    score += int(count(-1,  1) + count( 1, -1) >= inarow)    
    return score

#max is 4
def board_eval_ex(board, moves, column, mark):        
    inarow = config.inarow - 1  
    inv_mark = 1 if mark == 2 else 2
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])

    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                return i - 1
        return inarow
    score = 0 
    
    if  count(1, 0) + count(-1, 0) >= inarow:
        score += 1            
    if  count(0, 1) + count(0, -1) >= inarow:
        score += 1
    if  count(-1, -1) + count(1, 1) >= inarow:
        score += 1
    if  count(-1, 1) + count(1, -1) >= inarow:
        score += 1    
    return score
    
#max is 
def board_eval_ex2(board, moves, column, mark):        
    inarow = config.inarow - 1  
    inv_mark = 1 if mark == 2 else 2
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])

    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                return i - 1
        return inarow
    score = 0
    score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)   #total number of possibilities - vertical        
    score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow)   #total number of possibilities - horizontal
    score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
    score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
    return score

#eval v3 - counts possibilities
def board_eval_ex3(board, moves, column, mark):        
    def board_eval_ex2(board, moves, row, column, mark):        
        inarow = config.inarow - 1  
        inv_mark = 1 if mark == 2 else 2        
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                    return i - 1
            return inarow
        score = 0
        score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)           
        score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow)           
        score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
        score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
        return score 
    
    inv_mark = 1 if mark == 2 else 2  
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
    score = board_eval_ex2(board, moves, row, column, mark)
    for r in range(rows):      
        for c in range(columns):
            if board[c + (r * columns)] == mark:
                score += board_eval_ex2(board, moves, r, c, mark)            
            elif board[c + (r * columns)] == inv_mark:
                score -= board_eval_ex2(board, moves, r, c, inv_mark)                                
    return score

#eval v4 - counts possibilities
def board_eval_ex4(board, moves, column, mark):        
    def board_eval_ex4_internal(board, moves, row, column, mark):        
        inarow = config.inarow - 1  
        inv_mark = 3 - mark         
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                    return i - 1
            return inarow
        
        def count_act(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
        score = 0
        score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow) * (count_act( 1,  0) + count_act(-1,  0))           
        score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow) * (count_act( 0,  1) + count_act( 0, -1))        
        score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow) * (count_act(-1, -1) + count_act( 1,  1))
        score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow) * (count_act(-1,  1) + count_act( 1, -1)) 
        return score 
    
    inv_mark = 3 - mark  
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
    score = board_eval_ex4_internal(board, moves, row, column, mark)
    for r in range(rows):      
        for c in range(columns):
            if board[c + (r * columns)] == mark:
                score += board_eval_ex4_internal(board, moves, r, c, mark)            
            elif board[c + (r * columns)] == inv_mark:
                score -= board_eval_ex4_internal(board, moves, r, c, inv_mark)                                
    return score

#eval v5 - counts 3-in row combinations facing empty cells 
def board_eval_ex5(board, moves, column, mark):        
    def board_eval_ex5_internal(board, moves, row, column, mark):        
        inarow = config.inarow - 1  
        inv_mark = 3 - mark             
        
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                    return i - 1
            return inarow
        score = 0
        score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)
        score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow) 
        score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)
        score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)
        return score 
    
    inv_mark = 3 - mark  
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
    score = 0
    board[column + (row * columns)] = mark
    for r in range(rows):      
        for c in range(columns):
            if board[c + (r * columns)] == 0:
                score += board_eval_ex5_internal(board, moves, r, c, mark)                        
                score -= board_eval_ex5_internal(board, moves, r, c, inv_mark)                                
    board[column + (row * columns)]  = 0
    return score

def board_eval_ex2_FAST(board, moves, column, mark):        
    inarow = config.inarow - 1  
    inv_mark = 1 if mark == 2 else 2
    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])

    def count_h(offset_column):
        r_offset = row * columns
        for i in range(1, inarow + 1):            
            c = column + offset_column * i
            if c < 0 or c >= columns or board[c + r_offset] == inv_mark:
                return i - 1
        return inarow
    
    def count_v(offset_row):
        for i in range(1, inarow + 1):
            r = row + offset_row * i            
            if r < 0 or r >= rows or board[column + (r * columns)] == inv_mark:
                return i - 1
        return inarow
    
    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or c < 0 or r >= rows  or c >= columns or board[c + (r * columns)] == inv_mark):
                return i - 1
        return inarow
    
    
    score = 0
    score += max(0, 1 + count_v( 1) + count_v(-1) - inarow)           
    score += max(0, 1 + count_h( 1) + count_h(-1) - inarow)           
    score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
    score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
    return score

def play_moves(moves, board):    
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 1 if mark == 2 else 2
    return mark

def print_board(board):
    for r in range(rows):
        print('-'.join([str(board[c + (r * columns)]) for c in range(columns)]) )

#%% Test
moves = '45454' 
board = columns * rows * [0]
mark = play_moves(moves, board)    

#board = [0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0, 0, 1, 2, 2, 1, 2, 0, 1, 2, 2, 2, 1, 2, 0]
#board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 1, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 2, 0, 0, 1, 1, 2, 1, 2, 0, 0]
#board = [2, 1, 2, 2, 0, 0, 1, 2, 2, 1, 2, 0, 0, 2, 2, 1, 2, 2, 0, 0, 1, 1, 2, 1, 1, 0, 0, 1, 1, 1, 1, 2, 1, 0, 2, 2, 1, 1, 1, 2, 2, 1]
#mark = 2
print_board(board)


moves = sum(1 if cell != 0 else 0 for cell in board)
print( [board_eval    (board, moves, column, mark)  for column in range(columns) if board[column]==0] )
print( [board_eval_ex (board, moves, column, mark)  for column in range(columns) if board[column]==0] )
print( [board_eval_ex2(board, moves, column, mark)  for column in range(columns) if board[column]==0] )
print( [board_eval_ex3(board, moves, column, mark)  for column in range(columns) if board[column]==0] )
print( [board_eval_ex4(board, moves, column, mark)  for column in range(columns) if board[column]==0] )
print( [board_eval_ex5(board, moves, column, mark)  for column in range(columns) if board[column]==0] )

%timeit [board_eval    (board, moves, column, mark)  for column in range(columns) if board[column]==0] 
%timeit [board_eval_ex (board, moves, column, mark)  for column in range(columns) if board[column]==0] #125 µs ± 1.94 µs per loop
%timeit [board_eval_ex3(board, moves, column, mark)  for column in range(columns) if board[column]==0] 

cProfile.run("[[board_eval_ex2(board, moves, column, mark) for column in range(columns) if board[column]==0] for a in range(10000)]")

