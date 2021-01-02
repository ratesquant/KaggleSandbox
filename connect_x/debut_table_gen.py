# -*- coding: utf-8 -*-
"""
Created on Sat Dec 26 21:51:58 2020

@author: chirokov
"""
import os
import cProfile
import json
import random
import time
import requests

import pickle
import zlib


from kaggle_environments import evaluate, make, utils
from os import listdir
from os.path import isfile, join
#import numpy as np
#from random import choice

DATA_FOLDER = 'D:/Github/KaggleSandbox/connect_x/'

env = make("connectx", debug=True)
#env.render()

from kaggle_environments.utils import structify
#board = obs.board
config = env.configuration    
columns = config.columns
rows = config.rows
size = rows * columns   

def play_moves(moves):    
    columns = config.columns
    rows = config.rows
    board = columns * rows * [0]            
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 3 - mark
    return board, mark

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


def gen_board_key(board):
    key_map = {0:'00',1:'01',2:'10'}
    #return hex(int(''.join([ key_map[c] for c in board]), 2))
    return format(int(''.join([ key_map[c] for c in board]), 2), 'x')

def gen_board_fromkey(hex_key):
    key_map = {'00':0,'01':1,'10':2}
    bin_str = format(int(hex_key, 16), 'b')
    bin_str = '0' * (2*rows*columns - len(bin_str)) + bin_str
    return [key_map[a+b] for a, b in zip(bin_str[0::2], bin_str[1::2])]

def position_depth(pos, best_score):    
    nb_moves = (config.columns * config.rows - len(pos)) - 2*best_score
    return nb_moves
    
#print_board(gen_board_fromkey('20004012008401202944'))
#timing 2 sec per turn + 60 sec or exceedance total (2.5)
# on average 4.5 /sec
#my_agent  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission/submission_NEG_v9d_debug.py")) 


#%% generate

#LOAD
with open(DATA_FOLDER + '/debut_table/move_scores.cache.json','r') as f: 
    #best_scores_cache = eval(f.read())
    best_scores_cache = json.load(f)

#SAVE
with open(DATA_FOLDER + '/debut_table/move_scores.cache.json','w') as f: 
    json.dump(best_scores_cache, f)
    
#position map
position_map = {gen_board_key(play_moves(move)[0]):data  for move, data in best_scores_cache.items()}
len(position_map)  #335895  

#position: 44444147535555 (best move is column 3)
#15197
for i in range(24):
    print('%d \t %d' % (i, len([k for k, v in best_scores_cache.items() if len(k) == i])))
       
 
#[k for k, v in best_scores_cache.items() if len(k) == 3]

max([v[0 ]for k, v in best_scores_cache.items()])
min([v[0 ]for k, v in best_scores_cache.items()])
max([max(v[1 ]) for k, v in best_scores_cache.items()])
min([min(v[1 ]) for k, v in best_scores_cache.items()])

load_counter = 0
#https://connect4.gamesolver.org/en/?pos=523264324           
def load_position_scores(pos):
    global load_counter
    
    board_key = gen_board_key(play_moves(pos)[0])
                  
    if pos in best_scores_cache:
        return (pos, best_scores_cache[pos][0], best_scores_cache[pos][1])
    elif board_key in position_map:
        return (pos, position_map[board_key][0], position_map[board_key][1])
    else:
        load_counter += 1
        print('loading %s (%d) - (%d)' % (pos, len(pos), load_counter))
        if load_counter % 2000 == 0:
            with open(DATA_FOLDER + '/debut_table/move_scores.cache_%s.json' % len(best_scores_cache),'w') as f:
                json.dump(best_scores_cache, f)            
        headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}
        time.sleep(0.1*random.random())
        response = requests.get('https://connect4.gamesolver.org/solve?pos=%s' % pos, headers=headers)
        if response.reason == 'OK':
            scores = response.json()['score']
            best_column = scores.index(max([c for c in scores if c < 100]))
            best_scores_cache[pos] = (best_column, scores)            
            position_map[board_key]= (best_column, scores)            
            return (pos, best_column, scores)

def generate_all_positions(board, mark, random_mark, depth, position):        
       columns = config.columns
       if depth <=0:
           return
       #board = move_to_board('527574511')
       for column in range(columns):
           if board[column] == 0 and is_win_ex(board, column, mark, False):               
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
           
def generate_hard_positions(board, mark, depth, position):        
    columns = config.columns
    if depth <=0:
        return
    for column in range(columns):
        if board[column] == 0 and is_win_ex(board, column, mark, False):               
            return                   
    
    res = None
    try:
        res = load_position_scores(position)
        best_score = max([c for c in res[2] if c < 100])   
        #print(res)
    except Exception as ex:
        print('%s %s [%s]' % (position, res, ex) )
        return    
    
    for column in [i for i, c in enumerate(res[2]) if c == best_score]:        
        row = get_move_row(board, column)              
        board[column + (row * columns)] = mark           
        generate_hard_positions(board[:], 3-mark, depth-1, position + str(column+1))            
        board[column + (row * columns)] = 0

#%% Run the load
board = columns * rows * [0]
generate_all_positions(board[:], 1, 1, 16, '')

board = columns * rows * [0]
generate_all_positions(board[:], 1, 2, 16, '')

board = columns * rows * [0]
generate_hard_positions(board[:], 1, 24, '')

for depth in range(24):
    print(depth)    
    generate_hard_positions(board[:], 1, depth, '')
#print_board(board)

#%% Analyze lost _games and load positions up to 24
plays_folder = 'D:/Github/KaggleSandbox/connect_x/analyzed_games/'
#play_filename = '5982532.json' #slow game

#all poosition up to 24
all_positions = []

for play_filename in [f for f in listdir(plays_folder) if isfile(join(plays_folder, f))]:
    with open(plays_folder + play_filename, 'r') as pfile:
        game_log = json.load(pfile)        
        board_list = [s[0]['observation']['board'] for s in game_log['steps']]
        position_list = ['']
        for b1, b2 in zip(board_list[:-1], board_list[1:]):
            move = [a2 == a1 for a1, a2 in zip(b1, b2)].index(False) % columns
            position_list.append( position_list[len(position_list)-1] + str(move + 1))
        all_positions = all_positions + [p for p in position_list if len(p)<=24]
    
            
[load_position_scores(pos) for pos in set(all_positions) ]


#%% Easy Positions
import sys
submission = utils.read_file(DATA_FOLDER + "/submission/submission_NEG_v10c_debug.py")
my_agent = utils.get_last_callable(submission)

for depth in range(42):
    print('%d \t %d' % (depth, len({pos:data for pos, data in best_scores_cache.items() if position_depth(pos, data[1][data[0]] ) == depth })) )
    
d5_pos = {pos:data for pos, data in best_scores_cache.items() if position_depth(pos, data[1][data[0]] ) <= 1 } 

{pos for pos, data in d5_pos if pos not in easy_positions}

my_test_pos = '746446637'
board, mark = play_moves(my_test_pos)
obs = structify({'board':board, 'mark':mark, 'remainingOverageTime':60})
config['my_max_time'] = 10
config['debug'] = True
my_agent(obs, config)
obs['debug']
best_scores_cache[my_test_pos]

#easy_positions = {}
for pos in d5_pos:    
    if pos not in easy_positions:
        data = best_scores_cache[pos]
        board, mark = play_moves(pos)
        obs = structify({'board':board, 'mark':mark, 'remainingOverageTime':60})
        config['my_max_time'] = 5
        config['debug'] = True
        res = my_agent(obs, config)
        best_columns = set([i for i, c in enumerate(data[1]) if c == data[1][data[0]]])
        is_solved = (obs['debug']['best_column'] in best_columns and data[1][data[0]] == obs['debug']['best_score'])
        print('%s [%s] %s' % (pos, is_solved, obs['debug']))    
        if is_solved:
            easy_positions[pos] = (res, position_depth(pos, data[1][data[0]]), obs['debug']['elapsed'])
    
len(easy_positions)
    
#LOAD easy positions
with open(DATA_FOLDER + '/debut_table/easy_positions.json','r') as f:     
    easy_positions = json.load(f)

#SAVE easy positions
with open(DATA_FOLDER + '/debut_table/easy_positions.json','w') as f: 
    json.dump(easy_positions, f)    
     
  
#%% Save debut table
debut_hashtable = {}
invalid_moves = []
win_moves = []

for move, col in best_scores_cache.items():        
    if move != '':
        try:            
            board1, mark1 = play_moves(move                )            
            board2, mark2 = play_moves(move + str(col[0]+1))            
            #is_win_position(move_to_board('125633456'))            
            if is_win_position(board1) or is_win_position(board2):
                win_moves.append(move)
            else:                  
                #move_to_board(move, config)
                #my_board_key = hash(tuple(board1))
                my_board_key = gen_board_key(board1)
                debut_hashtable[my_board_key] = col[0]                
        except Exception as ex:
            print(move)
            print(ex)
            invalid_moves.append(move)

len(debut_hashtable) #61378
len(best_scores_cache)
len(win_moves)

with open(DATA_FOLDER + '/debut_table/debut_hashtable.txt','w') as f: 
    f.write(str(debut_hashtable))
    
for move in win_moves:
    print('%s %s' % (move, best_scores_cache[move]))
    del best_scores_cache[move]

for move in invalid_moves:
    del best_scores_cache[move]
    
    
    # Compress:
debut_hashtable_compressed = zlib.compress(pickle.dumps(debut_hashtable))
with open(DATA_FOLDER + '/debut_table/debut_hashtable_compressed.txt','w') as f: 
    f.write(str(debut_hashtable_compressed))

# Get it back:
debut_hashtable_uncompressed = pickle.loads(zlib.decompress(debut_hashtable_compressed))


    
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