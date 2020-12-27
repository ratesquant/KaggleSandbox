# -*- coding: utf-8 -*-
"""
Created on Wed Dec 23 16:58:00 2020

@author: chirokov
"""
import os
import cProfile
import json
from kaggle_environments import evaluate, make, utils
import numpy as np
from time import time
from random import choice


#DATA_FOLDER = os.getenv('HOME') + '/source/github/KaggleSandbox/connect_x/' 
DATA_FOLDER = 'D:/Github/KaggleSandbox/connect_x/submission/'

from kaggle_environments.utils import structify
env = make("connectx", debug=True)
#env.render()

#board = obs.board
config = env.configuration    
columns = config.columns
rows = config.rows
size = rows * columns   

def play_moves(moves, board, config):    
    columns = config.columns
    rows = config.rows
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r f or r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 3 - mark
    return mark

def print_board(board):
    for r in range(rows):
        print('-'.join([str(board[c + (r * columns)]) for c in range(columns)]) )

#%% Save debut table

mark = 1
moves ='14142511'        
debug_out = dict()
board = columns * rows * [0]
mark = play_moves(moves, board, config)    
obs = structify({'board':board, 'mark':mark, 'remainingOverageTime':6000})
negamax_agent_ex(obs, config)
#my_agent( obs, config)

#%% Save debut table
import itertools

# 1: always start with middle column 4 
# 2: [1-7]
# 3: (1)[1-7] or 4[1-7]
# 4: (2)[1-7]
# 5: (3)[1-7]

#3th
x3={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 1], range(1, 8))}
x4={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 2], range(1, 8))}
x5={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 3], range(1, 8))}
x6={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 4], range(1, 8))}
x7={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 5], range(1, 8))}
x8={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 6], range(1, 8))}
x9={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 7], range(1, 8))}
x10={str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 8], range(1, 8))}


#moves are 1 based, value is column
with open('D:/Github/KaggleSandbox/connect_x/debut_table/moves.json','r') as f: 
    moves = json.loads(f.read())
    
len(moves)

with open('D:/Github/KaggleSandbox/connect_x/debut_table/moves.json','w') as f: 
    json.dump( moves, f)


{m:s for m, s in moves.items() if len(m) == 8}
[m for m, s in x6.items() if m not in moves]
[m for m, s in x7.items() if m not in moves]

for i in range(7):
    print([m for m, s  in moves.items() if (m + str(s)).count(str(i+1)) > 6])

for m in[ m for m, s  in moves.items() if (m + str(s)).count('4') > 6]:
    print(m)
    del moves[m]
    
debut_hashtable = {}

#convert moves to tables
for move,col in moves.items():    
    board = columns * rows * [0]
    mark = 1
    if move != '':
        mark = play_moves(move, board, config)
    debut_hashtable[hash(tuple(board))] = col - 1
    
str(debut_hashtable)

#save move table for analysis
with open(DATA_FOLDER + "debut_table", 'w') as file:
    for move,col in moves.items():    
        file.write('%s %s\n' % (move, 0) )

#read analyzed moves, column index starts from 1
with open(DATA_FOLDER + "debut_table.out.csv", 'r') as file:
    lines = file.readlines()
solved_moves = {l.split(',')[0]:int(l.split(',')[3])+1 for l in lines[1:]}

for m, col in solved_moves.items(): 
    if m in moves and moves[m] == 0:
        moves[m] = col
        
    
#%% Check Table
import sys
out = sys.stdout
#submission = utils.read_file(DATA_FOLDER + "submission_NEG_v9a.py")
submission = utils.read_file(DATA_FOLDER + "submission_NEG_v8b3.py")
my_agent = utils.get_last_callable(submission)

update_moves = {}

for move,col in moves.items():    
    board = columns * rows * [0]
    mark = 1
    if move != '':
        mark = play_moves(move, board, config)
    res = my_agent( structify({'board':board, 'mark':mark, 'remainingOverageTime':60}), config)
    if col == 0:
        update_moves[move] = res
    print('move: %s, best: %d, solution: %d, mach: %s' % (move, col - 1, res, res == col -1) )
    #debut_hashtable[hash(tuple(board))] = col - 1
    
#%% Check Table
import json 
import random
import time
import requests
headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}

#https://connect4.gamesolver.org/solve?pos=5

best_scores = {}
for move in list(x9.keys()):
    time.sleep(random.random())
    response = requests.get('https://connect4.gamesolver.org/solve?pos=%s' % move, headers=headers)
    if response.reason == 'OK':
        scores = response.json()['score']
        scores.index(max(scores))
        best_scores[move] = (scores.index(max(scores)), scores)
        print('%s: %s' % (move,scores) )
        
#save move table for analysis
with open('D:/Github/KaggleSandbox/connect_x/debut_table/move_table_7.csv', 'w') as file:
    for move,data in best_scores.items():    
        file.write('%s %s\n' % (move, data,) )

for move,data in best_scores.items(): 
    if len(move) == 8:
        #print(move)
        moves[move] = data[0] + 1

#with open('D:/Github/KaggleSandbox/connect_x/debut_table/move_scores.temp.txt','w') as f: 
#    f.write(json.dumps(best_scores))

with open('D:/Github/KaggleSandbox/connect_x/debut_table/move_scores.8.txt','r') as f: 
    #best_scores_ex = json.loads(f.read())
    best_scores_ex = eval(f.read())
    
with open('D:/Github/KaggleSandbox/connect_x/debut_table/move_table_7.csv', 'w') as file:
    for move,data in best_scores.items():    
        file.write('%s %s\n' % (move, data,) )

#check moves difference        
{k: (moves[k], v[0]+1, v[1]) for k, v in best_scores_ex.items() if moves[k] != v[0]+1}