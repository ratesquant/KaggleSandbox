#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jan 12 14:57:22 2020

@author: chirokov
"""
import os
import cProfile
from kaggle_environments import evaluate, make, utils
import numpy as np
import time
from random import choice

import matplotlib.pyplot as plt


env = make("connectx", debug=True)
env.render()

#%% Agent
   
def negamax_agent(obs, config):
    from random import choice    
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board) 
    
    nodes = 0
    max_nodes = 20000
    max_depth = 6 if made_moves < 25 else 20
    
    def board_eval(board, moves, column, mark):
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        score =0 
        if column > 0 and board[row * columns + column - 1] == mark:              #left same mark
            score += 1
        if (column < columns - 1 and board[row * columns + column + 1] == mark):  #right same mark
            score += 1        
        if row > 0 and column > 0 and board[(row - 1) * columns + column - 1] == mark:
            score += 1
        if row > 0 and column < columns - 1 and board[(row - 1) * columns + column + 1] == mark:
            score += 1           
        return score

    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark

    def is_win(board, column, mark, config, has_played=True):
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

    def negamax(board, mark, depth, alpha, beta, nodes):                 
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None, nodes)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column, nodes)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:               
                return (beta, None, nodes)  # prune the exploration if the [alpha;beta] window is empty.                           

        # Recursively check all columns.        
        best_score = -size               
        best_column = None
        for column in column_order: 
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                                        
                    nodes = nodes + 1
                    score = board_eval(board, moves, column, mark)                   
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _, nodes) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha, nodes)
                    score = score * -1            
                if score > best_score:
                    best_score = score
                    best_column = column            
                alpha = max(alpha, score) # reduce the [alpha;beta] window for next exploration, as we only                                                                   
                #print("mark: %s, d:%s, col:%s, score:%s (%s, %s)) alpha = %s beta = %s" % (mark, depth, column, score,best_score, best_column, alpha, beta))            
                if alpha >= beta or nodes > max_nodes:                        
                    return (alpha, best_column, nodes)  # prune the exploration if we find a possible move better than what we were looking for.                    
        return (alpha, best_column, nodes)
    
    best_score = 0
    if made_moves <= 1:
        best_column = columns//2
    else:
        best_score, best_column, nodes = negamax(obs.board[:], obs.mark, max_depth, -size, size, nodes)        
        #print(obs.mark, made_moves, best_score, best_column)        
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column, best_score, nodes

# This agent random chooses a non-empty column.
#configuration = {'timeout': 5, 'columns': 7, 'rows': 6, 'inarow': 4, 'steps': 1000}
#observation = {'board': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'mark': 1}
def my_agent(observation, configuration):
    #print([c for c in range(configuration.columns) if observation.board[c + configuration.columns*(configuration.rows-1)] == 0])
    from random import choice
    return choice([c for c in range(configuration.columns) if observation.board[c] == 0])

#%% Position Checker
   
DATA_FOLDER = os.getenv('HOME') + '/source/github/KaggleSandbox/connect_x/cpp' 

import pandas as pd 

data = pd.read_table(os.path.join(DATA_FOLDER, 'Test_ALL'), sep = ' ', header = None, names = ['move', 'score'])
data = pd.read_table(os.path.join(DATA_FOLDER, 'Test_L3_R1'), sep = ' ', header = None, names = ['move', 'score'])


from kaggle_environments.utils import structify
#board = obs.board
config = env.configuration    
columns = config.columns
rows = config.rows
size = rows * columns   
mark = 1

moves = '4455'

def play_moves(moves, board, config):    
    columns = config.columns
    rows = config.rows
    mark = 1
    for c in moves:  
        column = int(c)-1
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        mark = 1 if mark == 2 else 2
    return mark
        
board = columns * rows * [0]
mark = play_moves(moves, board, config)    
negamax_agent(structify({'board':board, 'mark':mark}) , config)
  
for move, score in  zip(data.move[1:10], data.score[1:10]):    
    board = columns * rows * [0]
    mark = play_moves(moves, board, config)    
    best_column, best_score = negamax_agent(structify({'board':board, 'mark':mark}), config)
    print(move, score, best_score)
    

#%% Check Move
#http://connect4.gamesolver.org/?pos=456276274266462724276371741543
move = '47715713331437527153255735112'
board = columns * rows * [0]
mark = play_moves(move, board, config)    
best_column, best_score, nodes = negamax_agent(structify({'board':board, 'mark':mark}), config)
print('%s col:%s, score:%s, nodes:%s' %(move, best_column, best_score, nodes))


#%% Board Eval Code
from scipy.stats import pearsonr

  
#check negamax position solver 
position_scores = list()
for move, score in  zip(data.move[:2000], data.score[:2000]):    
    board = columns * rows * [0]
    mark = play_moves(move, board, config)    
    start_time = time.time()
    best_column, best_score, nodes = negamax_agent(structify({'board':board, 'mark':mark}), config)
    elapsed_time = time.time() - start_time
    position_scores.append((move, score, best_score, best_column, nodes, elapsed_time))
  
pd.DataFrame(position_scores, columns = ['move', 'score', 'best_score', 'best_column', 'nodes', 'elapsed_time']).to_csv(os.path.join(DATA_FOLDER, 'Test_All_negamax.10L.csv'))      
    
plt.plot([p[1] for p in position_scores], [p[3] for p in position_scores], '.')    

    
%timeit [board_eval(board, col, 1)    for col in range(columns) if board[col] == 0]  
%timeit [board_eval_ex(board, col, 1)    for col in range(columns) if board[col] == 0]  
cProfile.run('board_eval_ex(board, 4, 1)')
