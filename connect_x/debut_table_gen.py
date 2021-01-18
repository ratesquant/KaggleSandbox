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
import gc
from datetime import datetime

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
len(position_map)  #1203058  

#position: 44444147535555 (best move is column 3)
#15197
for i in range(26):
    print('%d \t %d' % (i, len([k for k, v in best_scores_cache.items() if len(k) == i])))
       
#sorted([k for k, v in best_scores_cache.items() if len(k) == 21][-10:])
#[k for k, v in best_scores_cache.items() if len(k) == 3]

max([v[0 ]for k, v in best_scores_cache.items()])
min([v[0 ]for k, v in best_scores_cache.items()])
max([max(v[1 ]) for k, v in best_scores_cache.items()])
min([min(v[1 ]) for k, v in best_scores_cache.items()])

#https://connect4.gamesolver.org/en/?pos=523264324           
def load_position_scores(pos):
    global load_counter
    
    board_key = gen_board_key(play_moves(pos)[0])
                  
    if pos in best_scores_cache:
        return (pos, best_scores_cache[pos][0], best_scores_cache[pos][1])
    elif board_key in position_map:
        return (pos, position_map[board_key][0], position_map[board_key][1])
    else:
        n = len(best_scores_cache)
        if n % 200 == 0:
            print('loading %s (%d) - (%d) [%s]' % (pos, len(pos), n, datetime.now().strftime("%H:%M:%S")))
        if n % 5000 == 0:
            with open(DATA_FOLDER + '/debut_table/move_scores.cache_%s.json' % n,'w') as f:
                json.dump(best_scores_cache, f)            
        headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}
        #time.sleep(0.1*random.random())
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
           
def generate_complete_positions(board, mark, random_mark, depth, position):        
       columns = config.columns
       if depth <=0:
           return       
       for column in range(columns):
           if board[column] == 0 and is_win_ex(board, column, mark, False):               
               return                   
       if mark == random_mark:
           for column in range(columns):
               if board[column] == 0:
                   row = get_move_row(board, column)                                   
                   board[column + (row * columns)] = mark                   
                   generate_complete_positions(board[:], 3-mark, random_mark, depth-1, position + str(column+1))                   
                   board[column + (row * columns)] = 0
       else:
           res = load_position_scores(position)
           best_score = max([c for c in res[2] if c < 100])
           for column in [i for i, score in enumerate(res[2]) if score == best_score]:        
               row = get_move_row(board, column)              
               board[column + (row * columns)] = mark           
               generate_complete_positions(board[:], 3-mark, random_mark, depth-1, position + str(column+1))            
               board[column + (row * columns)] = 0
        
           
def generate_hard_positions(board, mark, depth, position):        
    columns = config.columns
    if depth <=0:
        return 0
    for column in range(columns):
        if board[column] == 0 and is_win_ex(board, column, mark, False):               
            return 0
    res = load_position_scores(position)
    best_score = max([c for c in res[2] if c < 100])   
     
    count = 1 
    
    for column in [i for i, score in enumerate(res[2]) if score == best_score]:        
        row = get_move_row(board, column)              
        board[column + (row * columns)] = mark           
        count += generate_hard_positions(board[:], 3-mark, depth-1, position + str(column+1))            
        board[column + (row * columns)] = 0
    return count
        
def generate_reasonable_positions(board, mark, depth, position):                    
    columns = config.columns
    if depth <=0:
        return 0
    for column in range(columns):
        if board[column] == 0 and is_win_ex(board, column, mark, False):               
            return 0
    res = load_position_scores(position)
    valid_scores = [c for c in res[2] if c < 100]
    
    if len(valid_scores) == 0:
        return 0        
    best_score = max(valid_scores)  
    
    count = 1      
       
    for column in [i for i, score in enumerate(res[2]) if (score < 100 and (score > 0 or best_score == score) ) ]:
        row = get_move_row(board, column)              
        board[column + (row * columns)] = mark           
        count += generate_reasonable_positions(board[:], 3-mark, depth-1, position + str(column+1))            
        board[column + (row * columns)] = 0
    return count

#%% Run the load

#15 - complete (goal is to reach 16)
board = columns * rows * [0]
generate_all_positions(board[:], 1, 1, 17, '')
generate_all_positions(board[:], 1, 2, 17, '')

#10 - complete (goal is to reach 16)
board = columns * rows * [0]
generate_complete_positions(board[:], 1, 1, 11, '')
generate_complete_positions(board[:], 1, 2, 11, '')


#23 [13'337'181], 22 [4'013'953] - complete (goal is to reach 24)
board = columns * rows * [0]
count = generate_hard_positions(board[:], 1, 23, '')

#23 [4'013'953] - complete (goal is to reach 24)
board = columns * rows * [0]
count = generate_reasonable_positions(board[:], 1, 23, '')

#%% Analyze games and load positions up to 24
plays_folder = 'D:/Github/KaggleSandbox/connect_x/analyzed_games/'
#play_filename = '5982532.json' #slow game

#all poosition up to 24
all_positions = []

for play_filename in [f for f in listdir(plays_folder) if isfile(join(plays_folder, f))]:
    with open(plays_folder + play_filename, 'r') as pfile:
        try:
            game_log = json.load(pfile)        
            board_list = [s[0]['observation']['board'] for s in game_log['steps']]
            position_list = ['']
            for b1, b2 in zip(board_list[:-1], board_list[1:]):
                move = [a2 == a1 for a1, a2 in zip(b1, b2)].index(False) % columns
                position_list.append( position_list[len(position_list)-1] + str(move + 1))
            all_positions = all_positions + [p for p in position_list if len(p)<=24]
        except:
            print(play_filename)
    
            
[load_position_scores(pos) for pos in set(all_positions) ]

#%% Analyze replays
with open(DATA_FOLDER + '/debut_table/all_replays.json','r') as f:     
    all_replays = set(json.load(f))
    
mid_game_positions = [pos for pos in all_replays if len(pos) == 20]
 
[load_position_scores(pos) for pos in mid_game_positions]
    
        

#%% Easy Positions
import gc
import sys
submission = utils.read_file(DATA_FOLDER + "/submission/submission_NEG_v10c_debug.py")
my_agent = utils.get_last_callable(submission)

for depth in range(42):
    print('%d \t %d' % (depth, len({pos:data for pos, data in best_scores_cache.items() if position_depth(pos, data[1][data[0]] ) == depth })) )
    
d5_pos = {pos:data for pos, data in best_scores_cache.items() if position_depth(pos, data[1][data[0]] ) <= 6 } 

len(d5_pos)

len([pos for pos, data in d5_pos.items() if pos not in easy_positions])

my_test_pos = '44'
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
        config['my_max_time'] = 8
        config['debug'] = True
        res = my_agent(obs, config)
        best_columns = set([i for i, c in enumerate(data[1]) if c == data[1][data[0]]])
        is_solved = (obs['debug']['best_column'] in best_columns and data[1][data[0]] == obs['debug']['best_score'])
        print('%s [%s] %s' % (pos, is_solved, obs['debug']))    
        if is_solved:
            easy_positions[pos] = (res, position_depth(pos, data[1][data[0]]), obs['debug']['elapsed'])
        if len(easy_positions) % 100 == 0:
            gc.collect()

len(easy_positions) #220013
    
#LOAD easy positions
with open(DATA_FOLDER + '/debut_table/easy_positions.json','r') as f:     
    easy_positions = json.load(f)

#SAVE easy positions
with open(DATA_FOLDER + '/debut_table/easy_positions.json','w') as f: 
    json.dump(easy_positions, f)    
    
for depth in range(7):
    print('%d %d' % (depth, len([pos for pos, data in easy_positions.items() if pos in best_scores_cache and position_depth(pos, best_scores_cache[pos][1][best_scores_cache[pos][0]] ) == depth]))) 
#[pos for pos, data in easy_positions.items() if pos not in best_scores_cache]
{pos:data for pos, data in easy_positions.items() if pos in best_scores_cache and position_depth(pos, best_scores_cache[pos][1][best_scores_cache[pos][0]] ) == 5}  
     
#gc.get_count()
#gc.collect()
  
#%% Save debut table
debut_hashtable = {}
invalid_moves = []
win_moves = []

for move, col in best_scores_cache.items():        
    if move not in easy_positions:
        try:            
            board1, mark1 = play_moves(move                )            
            board2, mark2 = play_moves(move + str(col[0]+1))            
            #is_win_position(move_to_board('125633456'))            
            if is_win_position(board1) or is_win_position(board2):
                win_moves.append(move)
            else:                  
                my_board_key = gen_board_key(board1)
                debut_hashtable[my_board_key] = col[0]                
        except Exception as ex:
            print(move)
            print(ex)
            invalid_moves.append(move)

len(debut_hashtable) #1006236
len(best_scores_cache)
len(win_moves)

#SAVE, 1006236
with open(DATA_FOLDER + '/debut_table/debut_hashtable.txt','w') as f: 
    f.write(str(debut_hashtable))
    
#LOAD    
with open(DATA_FOLDER + '/debut_table/debut_hashtable.txt','r') as f: 
    debut_hashtable = eval(f.read())
    
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

#%% Add debut table to the file

agent_file = DATA_FOLDER + '/submission/submission_NEG_v10f.py'
with open(agent_file, 'r') as f:
    my_code = f.read()
 
with open(DATA_FOLDER + '/debut_table/debut_hashtable.txt','r') as f: 
    debut_hashtable = eval(f.read())
    
with open(agent_file + 'debut.v4.py', 'w') as f:
    f.write('debut_table = %s' % str(debut_hashtable) )
    f.write('\n')
    f.write(my_code)
    
#%% Save Debut positions
debut_positions = {}
invalid_moves = []
win_moves = []

for move, data in best_scores_cache.items():        
    if move not in easy_positions:
        try:            
            board, mark = play_moves(move)            
            if is_win_position(board):
                win_moves.append(move)
            else:                  
                my_board_key = gen_board_key(board)
                best_score = max([c for c in data[1] if c < 100])    
                debut_positions[my_board_key] =  [i for i, score in enumerate(data[1]) if score == best_score]                
        except Exception as ex:
            print(move)
            print(ex)
            invalid_moves.append(move)

len(debut_positions) #1006070
len(best_scores_cache)
len(win_moves)

with open(DATA_FOLDER + '/debut_table/debut_positions.txt','w') as f: 
    f.write(str(debut_positions))

#compression    
#debut_positions_compressed = zlib.compress(pickle.dumps(debut_positions))
debut_positions_compressed = zlib.compress(str(debut_positions).encode())
with open(DATA_FOLDER + '/debut_table/debut_positions_compressed.txt','w') as f: 
    f.write(str(debut_positions_compressed))    
debut_positions_ex = eval(zlib.decompress(debut_positions_compressed))
   
#%% Add debut positions to the file

agent_file = DATA_FOLDER + '/submission/submission_NEG_v11a.py'
with open(agent_file, 'r') as f:
    my_code = f.read()
 
with open(DATA_FOLDER + '/debut_table/debut_positions.txt','r') as f: 
    debut_positions = eval(f.read())
    
with open(agent_file + '.v4.debut.pos.py', 'w') as f:
    f.write('debut_table = %s' % str(debut_positions) )
    f.write('\n')
    f.write(my_code)
       

    
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

