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
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
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

#4th
[str(x1) + str(x2) for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 1], range(1, 8))]

#5th
{str(x1) + str(x2):-1 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 2], range(1, 8))}

#6th
{str(x1) + str(x2):-1 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 3], range(1, 8))}

#7th - only when 5th moves are defined
{str(x1) + str(x2):0 for x1, x2, in itertools.product([str(k) + str(v) for k, v in moves.items() if len(k) == 5], range(1, 8))}

#moves are 1 based, value is column
moves = {'':4,
         '1':4,'2':3,'3':4,'4':4,'5':4,'6':5,'7':4,              #2nd    
         '41':4,'42':2,'43':6,'44':4, '45':2, '46':2, '47':4,    #3rd
         '141':4,'142':4,'143':4,'144':4,'145':4,'146':4,'147':3,#4rd
         '231':3,'232':2,'233':3,'234':4,'235':3,'236':3,'237':3,'341':4,'342':4,'343':3,'344':4,'345':4,'346':4,'347':4, '441':4,'442':3,'443':2,'444':4,'445':3,'446':5,'447':4,         '541':4,'542':4,'543':4,'544':5,'545':5,'546':4,'547':4,         '651':2,'652':5,'653':5,'654':4,'655':5,'656':6,'657':5,         '741':3,'742':4,'743':4,'744':4,'745':4,'746':4,'747':4,
         '4141': 4, '4142': 4, '4143': 4, '4144': 4, '4145': 4, '4146': 4, '4147': 3, '4221': 2, '4222': 4, '4223': 1, '4224': 2, '4225': 4, '4226': 4, '4227': 4, '4361': 3, '4362': 4, '4363': 3, '4364': 4, '4365': 5, '4366': 7, '4367': 6, '4441': 5, '4442': 4, '4443': 3, '4444': 4, '4445': 4, '4446': 4, '4447': 3, '4521': 2, '4522': 1, '4523': 3, '4524': 4, '4525': 1, '4526': 4, '4527': 1, '4621': 4, '4622': 3, '4623': 2, '4624': 3, '4625': 4, '4626': 3, '4627': 3, '4741': 3, '4742': 4, '4743': 4, '4744': 4, '4745': 4, '4746': 3, '4747': 3, 
         '14141': 1, '14142': 4, '14143': 4, '14144': 5, '14145': 4, '14146': 5, '14147': 3, '14241': 4, '14242': 4, '14243': 2, '14244': 2, '14245': 2, '14246': 1, '14247': 4, '14341': 4, '14342': 2, '14343': 3, '14344': 3, '14345': 3, '14346': 3, '14347': 1, '14441': 3, '14442': 4, '14443': 3, '14444': 6, '14445': 4, '14446': 4, '14447': 3, '14541': 4, '14542': 2, '14543': 3, '14544': 5, '14545': 4, '14546': 4, '14547': 4, '14641': 5, '14642': 1, '14643': 3, '14644': 4, '14645': 4, '14646': 4, '14647': 4, '14731': 5, '14732': 4, '14733': 5, '14734': 5, '14735': 3, '14736': 3, '14737': 5, '23131': 3, '23132': 2, '23133': 2, '23134': 3, '23135': 1, '23136': 1, '23137': 3, '23221': 2, '23222': 3, '23223': 3, '23224': 3, '23225': 3, '23226': 2, '23227': 2, '23331': 3, '23332': 3, '23333': 2, '23334': 2, '23335': 3, '23336': 2, '23337': 3, '23441': 4, '23442': 4, '23443': 4, '23444': 3, '23445': 4, '23446': 3, '23447': 3, '23531': 1, '23532': 3, '23533': 3, '23534': 2, '23535': 5, '23536': 3, '23537': 3, '23631': 1, '23632': 3, '23633': 3, '23634': 4, '23635': 3, '23636': 2, '23637': 3, '23731': 3, '23732': 3, '23733': 3, '23734': 4, '23735': 3, '23736': 3, '23737': 3, '34141': 4, '34142': 2, '34143': 3, '34144': 3, '34145': 3, '34146': 3, '34147': 1, '34241': 2, '34242': 4, '34243': 4, '34244': 4, '34245': 4, '34246': 3, '34247': 2, '34331': 4, '34332': 2, '34333': 4, '34334': 4, '34335': 3, '34336': 4, '34337': 4, '34441': 3, '34442': 4, '34443': 4, '34444': 3, '34445': 4, '34446': 4, '34447': 4, '34541': 3, '34542': 4, '34543': 4, '34544': 3, '34545': 4, '34546': 3, '34547': 3, '34641': 3, '34642': 3, '34643': 4, '34644': 4, '34645': 3, '34646': 4, '34647': 3, '34741': 1, '34742': 2, '34743': 4, '34744': 3, '34745': 3, '34746': 3, '34747': 3, '44141': 4, '44142': 3, '44143': 2, '44144': 3, '44145': 4, '44146': 3, '44147': 4, '44231': 4, '44232': 4, '44233': 4, '44234': 3, '44235': 4, '44236': 3, '44237': 3, '44321': 2, '44322': 2, '44323': 4, '44324': 4, '44325': 6, '44326': 5, '44327': 4, '44441': 2, '44442': 1, '44443': 2, '44444': 1, '44445': 3, '44446': 5, '44447': 2, '44531': 3, '44532': 4, '44533': 3, '44534': 3, '44535': 5, '44536': 7, '44537': 6, '44651': 4, '44652': 4, '44653': 4, '44654': 5, '44655': 4, '44656': 4, '44657': 4, '44741': 4, '44742': 3, '44743': 2, '44744': 5, '44745': 6, '44746': 5, '44747': 4, '54141': 4, '54142': 2, '54143': 3, '54144': 5, '54145': 4, '54146': 4, '54147': 4, '54241': 2, '54242': 2, '54243': 4, '54244': 2, '54245': 4, '54246': 4, '54247': 2, '54341': 3, '54342': 4, '54343': 4, '54344': 3, '54345': 4, '54346': 3, '54347': 3, '54451': 4, '54452': 4, '54453': 5, '54454': 1, '54455': 4, '54456': 4, '54457': 4, '54551': 4, '54552': 4, '54553': 3, '54554': 4, '54555': 4, '54556': 4, '54557': 4, '54641': 4, '54642': 4, '54643': 3, '54644': 4, '54645': 4, '54646': 4, '54647': 1, '54741': 4, '54742': 2, '54743': 3, '54744': 5, '54745': 4, '54746': 1, '54747': 3, '65121': 3, '65122': 2, '65123': 5, '65124': 4, '65125': 2, '65126': 2, '65127': 1, '65251': 3, '65252': 2, '65253': 1, '65254': 4, '65255': 5, '65256': 5, '65257': 1, '65351': 2, '65352': 1, '65353': 3, '65354': 4, '65355': 3, '65356': 5, '65357': 1, '65441': 4, '65442': 4, '65443': 4, '65444': 5, '65445': 4, '65446': 4, '65447': 4, '65551': 5, '65552': 1, '65553': 5, '65554': 2, '65555': 6, '65556': 5, '65557': 5, '65661': 1, '65662': 1, '65663': 5, '65664': 4, '65665': 5, '65666': 5, '65667': 1, '65751': 3, '65752': 1, '65753': 1, '65754': 5, '65755': 5, '65756': 5, '65757': 5, '74131': 5, '74132': 4, '74133': 5, '74134': 5, '74135': 3, '74136': 3, '74137': 5, '74241': 4, '74242': 4, '74243': 2, '74244': 2, '74245': 2, '74246': 1, '74247': 3, '74341': 1, '74342': 2, '74343': 4, '74344': 3, '74345': 3, '74346': 3, '74347': 3, '74441': 3, '74442': 4, '74443': 4, '74444': 2, '74445': 5, '74446': 2, '74447': 2, '74541': 4, '74542': 2, '74543': 3, '74544': 5, '74545': 4, '74546': 1, '74547': 3, '74641': 4, '74642': 1, '74643': 3, '74644': 6, '74645': 1, '74646': 3, '74647': 2, '74741': 3, '74742': 3, '74743': 3, '74744': 3, '74745': 3, '74746': 2, '74747': 7
         }
len(moves)

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
import random
import time
import requests
headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}

#https://connect4.gamesolver.org/solve?pos=5

best_scores = {}
for move in list(x7.keys()):
    time.sleep(random.randrange(1, 3))
    response = requests.get('https://connect4.gamesolver.org/solve?pos=%s' % move, headers=headers)
    if response.reason == 'OK':
        scores = response.json()['score']
        scores.index(max(scores))
        best_scores[move] = (scores.index(max(scores)), scores)
        print('%s: %s' % (move,scores) )
        
#save move table for analysis
with open(DATA_FOLDER + "move_table_", 'w') as file:
    for move,data in best_scores.items():    
        file.write('%s %s\n' % (move, data,) )
