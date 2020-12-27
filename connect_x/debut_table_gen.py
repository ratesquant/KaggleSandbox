# -*- coding: utf-8 -*-
"""
Created on Sat Dec 26 21:51:58 2020

@author: chirokov
"""
import os
import cProfile
import json
from kaggle_environments import evaluate, make, utils
import numpy as np
from time import time
from random import choice

DATA_FOLDER = 'D:/Github/KaggleSandbox/connect_x/'

env = make("connectx", debug=True)
#env.render()

from kaggle_environments.utils import structify
#board = obs.board
config = env.configuration    
columns = config.columns
rows = config.rows
size = rows * columns   

def play_moves(moves, board):    
    columns = config.columns
    rows = config.rows
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 3 - mark
    return mark

def print_board(board):
    for r in range(rows):
        print('-'.join([str(board[c + (r * columns)]) for c in range(columns)]) )
        
def get_move_row(board, column):        
    columns = config.columns
    rows = config.rows
    for r in range(rows-1, 0, -1):
        if board[column + (r * columns)] == 0:
            return r
    return 0 

def is_win(board, row, column, mark):
    columns = config.columns
    rows = config.rows
    inarow = config.inarow - 1        

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

def is_win_ex(board, column, mark, has_played=True):
    columns = config.columns
    rows = config.rows
    inarow = config.inarow - 1
    row = (
        min([r for r in range(rows) if board[column + (r * columns)] == mark])
        if has_played else max([r for r in range(rows) if board[column + (r * columns)] == 0])
    )
    
    def count(offset_row, offset_column):
        for i in range(1, inarow + 1):
            r = row + offset_row * i
            c = column + offset_column * i
            if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                return i - 1
        return inarow
    
    return (
        count(1, 0) >= inarow  # vertical.
        or (count(0, 1) + count(0, -1)) >= inarow  # horizontal.
        or (count(-1, -1) + count(1, 1)) >= inarow  # top left diagonal.
        or (count(-1, 1) + count(1, -1)) >= inarow  # top right diagonal.
    )

def is_win_position(board):
    for col in range(columns):
        if len([r for r in range(rows) if board[col + (r * columns)] == 1]) >0 and is_win_ex(board, col, 1) :
            return True
        if len([r for r in range(rows) if board[col + (r * columns)] == 2]) >0 and is_win_ex(board, col, 2) :
            return True
    return False 

def move_to_board(move):
    board = config.columns * config.rows * [0]
    mark = play_moves(move, board)
    return board

#timing 2 sec per turn + 60 sec or exceedance total (2.5)
# on average 4.5 /sec
my_agent  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission/submission_NEG_v9d_debug.py")) 


#%% generate

import json 
import random
import time
import requests

#load best scores
with open(DATA_FOLDER + '/debut_table/move_scores.8.txt','r') as f: 
    best_scores_cache = eval(f.read())

#LOAD
with open(DATA_FOLDER + '/debut_table/move_scores.cache.json','r') as f: 
    #best_scores_cache = eval(f.read())
    best_scores_cache = json.load(f)

#SAVE
with open(DATA_FOLDER + '/debut_table/move_scores.cache.json','w') as f: 
    json.dump(best_scores_cache, f)
    
board_cache = {hash(tuple(move_to_board(pos))):data for pos, data in best_scores_cache.items()}
len(board_cache)    

#15197
for i in range(13):
    print('%d %d' % (i, len([k for k, v in best_scores_cache.items() if len(k) == i])))

max([v[0 ]for k, v in best_scores_cache.items()])
min([v[0 ]for k, v in best_scores_cache.items()])
max([max(v[1 ]) for k, v in best_scores_cache.items()])
min([min(v[1 ]) for k, v in best_scores_cache.items()])

#https://connect4.gamesolver.org/en/?pos=523264324           
def load_position_scores(pos):
    if pos in best_scores_cache:
        return (pos, best_scores_cache[pos][0], best_scores_cache[pos][1])
    else:
        print('loading solution for %s' % pos)
        #return (pos, 4, None)
        headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}
        time.sleep(random.random())
        response = requests.get('https://connect4.gamesolver.org/solve?pos=%s' % pos, headers=headers)
        if response.reason == 'OK':
            scores = response.json()['score']
            best_column = scores.index(max([c for c in scores if c < 100]))
            best_scores_cache[pos] = (best_column, scores)            
            return (pos, best_column, scores)

best_scores_cache['4522']

board = columns * rows * [0]
generate_all_positions(board[:], 1, 1, 12, '')
generate_all_positions(board[:], 1, 2, 12, '')

#print_board(board)

def generate_all_positions(board, mark, random_mark, depth, position):        
       columns = config.columns
       if depth <=0:
           return
       #board = move_to_board('527574511')
       for column in range(columns):
           if board[column] == 0 and is_win_ex(board, column, mark, False):               
               #print('win %s %s %s %s' % (position, column, mark, random_mark))
               #print_board(board)
               return                   
       if mark == random_mark:
           for column in range(columns):
               if board[column] == 0:
                   row = get_move_row(board, column)                                   
                   board[column + (row * columns)] = mark                   
                   generate_all_positions(board[:], 3-mark, random_mark, depth-1, position + str(column+1))                   
                   board[column + (row * columns)] = 0
       else:
           res = load_position_scores(position)
           column = res[1]
           row = get_move_row(board, column)              
           board[column + (row * columns)] = mark           
           generate_all_positions(board[:], 3-mark, random_mark, depth-1, position + str(column+1))            
           board[column + (row * columns)] = 0

#%% Save debut table
debut_hashtable = {}
invalid_moves = []
win_moves = []

for move, col in best_scores_cache.items():        
    if move != '':
        try:
            mark = 1
            board1 = columns * rows * [0]
            board2 = columns * rows * [0]            
            mark1 = play_moves(move                , board1)            
            mark2 = play_moves(move + str(col[0]+1), board2)            
            #is_win_position(move_to_board('125633456'))            
            if is_win_position(board1) or is_win_position(board2):
                win_moves.append(move)
            else:  
                #board_key = ''.join([str(c) for c in board])
                #move_to_board(move, config)
                board_key = hash(tuple(board1))
                debut_hashtable[board_key] = col[0]                
        except Exception as ex:
            print(move)
            print(ex)
            invalid_moves.append(move)

len(debut_hashtable)
len(best_scores_cache)
len(win_moves)

for move in win_moves:
    print('%s %s' % (move, best_scores_cache[move]))
    del best_scores_cache[move]

for move in invalid_moves:
    del best_scores_cache[move]
    
with open(DATA_FOLDER + '/debut_table/debut_hashtable.txt','w') as f: 
    f.write(str(debut_hashtable))
    
    
#%% Sanity check
len(best_scores_cache)
sum([d[0]-d[1].index(max([c for c in d[1] if c < 100])) for m, d in best_scores_cache.items()]) #should be zero

pos_fix = []
for k, d in best_scores_cache.items():
    if d[0] != d[1].index(max([c for c in d[1] if c < 100])):
        pos_fix.append(k)

for pos in pos_fix:        
    d = best_scores_cache[pos]
    best_scores_cache[pos] = [d[1].index(max([c for c in d[1] if c < 100])), d[1]]   
