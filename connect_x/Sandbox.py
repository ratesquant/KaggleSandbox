board[column#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Jan 11 16:27:39 2020

@author: chirokov
"""
#pip install 'kaggle-environments>=0.1.6'
import os
import cProfile
from kaggle_environments import evaluate, make, utils
import numpy as np
from random import choice

env = make("connectx", debug=True)
env.render()

#%%

def evaluator_agent(obs, config):
    from random import choice, choices
    columns = config.columns
    rows = config.rows
    size = rows * columns  
    board = obs.board[:]
    
    def board_eval_prev(board, moves, column, mark):
       row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
       score =0 # (size + 1 - moves) / 2
       if column > 0 and board[row * columns + column - 1] == mark:              #left same mark
           score += 1
       if (column < columns - 1 and board[row * columns + column + 1] == mark):  #right same mark
           score += 1        
       if row < rows - 2 and board[(row + 1) * columns + column] == mark:            
           score += 1
       if row < rows - 2 and column < columns - 1 and board[(row + 1) * columns + column + 1] == mark:            
           score += 1
       if row < rows - 2 and column > 0           and board[(row + 1) * columns + column - 1] == mark:            
           score += 1
       if row > 0 and column > 0 and board[(row - 1) * columns + column - 1] == mark:
           score += 1
       if row > 0 and column < columns - 1 and board[(row - 1) * columns + column + 1] == mark:
           score += 1
       return score
   
    
    def board_eval(board, moves, column, mark):        
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        score = 0 
        offsets = [(-1, -1), (-1, 0), (-1,1), (0, 1), (1,1), (1,0), (1,-1)]
        for co, ro in offsets:
            col_n = co + column
            row_n = ro + row
            if col_n >= 0 and row_n >= 0 and row_n < rows and col_n < columns and board[row_n * columns + col_n] == mark:
                score += 1
            print(co, ro, col_n, row_n, score)
        return score
    
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
    
    moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

    # Tie Game
    if moves == size:
        return choice([c for c in range(columns) if obs.board[c] == 0])

    # Can win next.
    for column in range(columns):
        if board[column] == 0 and is_win(board, column, mark, config, False):
            return column
    
    best_score = -size               
    best_column = None
    for column in range(columns):
        if board[column] == 0:
            score = board_eval(board, moves, column, mark)    
            if score > best_score:
                best_score = score
                best_column = column
    return best_column
                    
    
def negamax_agent(obs, config):
    from random import choice, choices
    columns = config.columns
    rows = config.rows
    size = rows * columns        
    
    max_depth = 6
    
    def board_eval_prev(board, moves, column, mark):
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        score =0 # (size + 1 - moves) / 2
        if column > 0 and board[row * columns + column - 1] == mark:              #left same mark
            score += 1
        if (column < columns - 1 and board[row * columns + column + 1] == mark):  #right same mark
            score += 1        
        if row < rows - 2 and board[(row + 1) * columns + column] == mark:            
            score += 1
        if row < rows - 2 and column < columns - 1 and board[(row + 1) * columns + column + 1] == mark:            
            score += 1
        if row < rows - 2 and column > 0           and board[(row + 1) * columns + column - 1] == mark:            
            score += 1
        if row > 0 and column > 0 and board[(row - 1) * columns + column - 1] == mark:
            score += 1
        if row > 0 and column < columns - 1 and board[(row - 1) * columns + column + 1] == mark:
            score += 1
        return score
    
    def board_eval(board, moves, column, mark):        
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        score = 0 
        offsets = [(-1, -1), (-1, 0), (-1,1), (0, 1), (1,1), (1,0), (1,-1)]
        for co, ro in offsets:
            col_n = co + column
            row_n = ro + row
            if col_n >= 0 and row_n >= 0 and row_n < rows and col_n < columns and board[row_n * columns + col_n] == mark:
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

    def negamax(board, mark, depth, alpha, beta):        
        moves = sum(1 if cell != 0 else 0 for cell in board) #moves already made

        # Tie Game
        if moves == size:
            return (0, None)

        # Can win next.
        for column in range(columns):
            if board[column] == 0 and is_win(board, column, mark, config, False):
                return ((size + 1 - moves) / 2, column)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:               
                return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.                           

        #move ordering
        #possible_moves = [(column, board_eval(board, moves, column, mark)) for column in range(columns) if board[column] == 0]  
        #possible_moves.sort(key = lambda x: x[1])                
        possible_moves = [(column,0) for column in range(columns) if board[column] == 0]                        
                
        # Recursively check all columns.        
        best_score = -size               
        best_column = None
        for column,_ in possible_moves:            
            # Max depth reached. Score based on cell proximity for a clustering effect.
            if depth <= 0:                                        
                score = board_eval(board, moves, column, mark)                   
            else:
                next_board = board[:]
                play(next_board, column, mark, config)
                (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                score = score * -1            
            if score > best_score:
                best_score = score
                best_column = column            
            alpha = max(alpha, score) # reduce the [alpha;beta] window for next exploration, as we only                                                                   
            #print("mark: %s, d:%s, col:%s, score:%s (%s, %s)) alpha = %s beta = %s" % (mark, depth, column, score,best_score, best_column, alpha, beta))            
            if alpha >= beta:                        
                return (alpha, best_column)  # prune the exploration if we find a possible move better than what we were looking for.                    
        return (alpha, best_column)

    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board) 
    if made_moves == 0:
        best_column = columns//2
    else:
        best_score, best_column = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
        #print(obs.mark, made_moves, best_score, best_column)    
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])
    return best_column

# This agent random chooses a non-empty column.
#configuration = {'timeout': 5, 'columns': 7, 'rows': 6, 'inarow': 4, 'steps': 1000}
#observation = {'board': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'mark': 1}
def my_agent(observation, configuration):
    #print([c for c in range(configuration.columns) if observation.board[c + configuration.columns*(configuration.rows-1)] == 0])
    from random import choice
    return choice([c for c in range(configuration.columns) if observation.board[c] == 0])

#%% Debug Negamax
    
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
negamax_agent(structify({'board':board, 'mark':mark}) , config, 11)
negamax_agent(structify({'board':board, 'mark':mark}) , config, 13)
    
board = [0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0, 0, 1, 2, 2, 1, 2, 0, 1, 2, 2, 2, 1, 2, 0]
board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 1, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 2, 0, 0, 1, 1, 2, 1, 2, 0, 0]

moves = sum(1 if cell != 0 else 0 for cell in board)
[board_eval(board, moves, column, mark)  for column in range(columns) if board[column]==0]

[board[column] == 0 and is_win(board, column, mark, config, False) for column in range(columns)]

for column in range(columns):
    if board[column] == 0:
        next_board = board[:]
        play(next_board, column, mark, config)
        (score, _) = negamax(next_board, 1 if mark == 2 else 2, 10, -size, size)
        score = score * -1   
        print(column, score)
    
best_score, best_column = negamax(board[:], mark, 20, -size, size)  

negamax_agent(structify({'board':board, 'mark':1}) , config)

#%% Debug move
board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 1, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 2, 0, 0, 1, 1, 2, 1, 2, 0, 0]
negamax_agent(structify({'board':board, 'mark':1}) , config)

    
#%% Test
    
env.reset()
# Play as the first agent against default "random" agent.
#env.run([my_agent, "random"])
#env.run([my_agent, "negamax"])
#env.run([negamax_agent, "negamax"])
#env.run(["negamax", negamax_agent])
#env.run([negamax_agent, negamax_agent])
#env.run(["negamax", negamax_agent])
#env.run([negamax_agent, "random"])
env.run([negamax_agent, "negamax"])
env.render()

#%% Profile
env.reset()
trainer = env.train([None, "negamax"])

observation = trainer.reset()

my_action = negamax_agent(observation, env.configuration)    
observation, reward, done, info = trainer.step(my_action)   

#is_win(observation.board, 2, observation.mark, env.configuration)
%timeit negamax_agent(observation, env.configuration)  
cProfile.run('negamax_agent(observation, env.configuration)  ')

#%% Debug
# Play as first position against random agent.
env.reset()
trainer = env.train([None, 'negamax'])
#trainer = env.train(["negamax", None])

observation = trainer.reset()

while not env.done:
    #my_action = my_agent(observation, env.configuration)    
    my_action = negamax_agent(observation, env.configuration)    
    observation, reward, done, info = trainer.step(my_action)    
    print("My Action: %s, %s [%s]" % (my_action, reward, done))
    #env.render(mode="ipython", width=100, height=90, header=False, controls=False)
env.render()

#%% Evaluate
def mean_reward(rewards):
    return sum(r[0] for r in rewards) / sum(r[0] + r[1] for r in rewards)

# Run multiple episodes to estimate its performance.
#print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [my_agent, "random"], num_episodes=10)))
#print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [my_agent, "negamax"], num_episodes=10)))
    
print("My Agent vs My Agent (Depth):", mean_reward(evaluate("connectx", [negamax_agent, lambda x, y: negamax_agent(x, y, 5) ], num_episodes=10)))

print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent, "random"], num_episodes=10)))
print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [negamax_agent, "negamax"], num_episodes=10)))
print("Negamax vs My Agent:", mean_reward(evaluate("connectx", ["negamax", negamax_agent], num_episodes=10)))
print("My Agent vs My Agent:", mean_reward(evaluate("connectx", [negamax_agent, negamax_agent], num_episodes=10)))

print("My Agent vs My Agent:", mean_reward(evaluate("connectx", [evaluator_agent, "random"], num_episodes=10)))

#%% Evaluate
import matplotlib.pyplot as plt

scores = [mean_reward(evaluate("connectx", [lambda obs, config : negamax_agent(obs, config, depth), "negamax"], num_episodes=100)) for depth in range(10)]

#scores = [mean_reward(evaluate("connectx", [lambda obs, config : negamax_agent(obs, config, depth), "random"], num_episodes=10)) for depth in range(10)]

plt.plot(scores, '.-')
plt.grid()

# 
scores = [mean_reward(evaluate("connectx", [lambda obs, config : negamax_agent(obs, config, depth),  "random"], num_episodes=10)) for depth in range(11)]

plt.plot(scores, '.-')
plt.grid()


#%% Write Submission File
DATA_FOLDER = os.getenv('HOME') + '/source/github/KaggleSandbox/connect_x/' 

import inspect
import os

def write_agent_to_file(function, file):
    with open(file, "a" if os.path.exists(file) else "w") as f:
        f.write(inspect.getsource(function))
        print(function, "written to", file)

write_agent_to_file(negamax_agent, DATA_FOLDER + "submission.py")

#%% Validate

import sys
out = sys.stdout
submission = utils.read_file(DATA_FOLDER + "submission.py")
agent = utils.get_last_callable(submission)
sys.stdout = out

env = make("connectx", debug=True)
env.run([agent, agent])
print("Success!" if env.state[0].status == env.state[1].status == "DONE" else "Failed...")
    