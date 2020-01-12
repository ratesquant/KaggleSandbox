#!/usr/bin/env python3
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

env = make("connectx", debug=True)
env.render()

#%%
def negamax_agent(obs, config):
    columns = config.columns
    rows = config.rows
    size = rows * columns
    calls = 0 

    # Due to compute/time constraints the tree depth must be limited.
    max_depth = min(8*columns, size - sum(1 if cell != 0 else 0 for cell in obs.board[:]))    
    
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
            
        max_score = (size + 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
           beta = max_score                    # there is no need to keep beta above our max possible score.
           if alpha >= beta:               
               return (beta, None)  # prune the exploration if the [alpha;beta] window is empty.               
            
        if depth == max_depth:
            all_moves = []
            for column in range(columns):
                if board[column] == 0:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only    
                    all_moves.append(columns, score)
            

        # Recursively check all columns.        
        best_score = -size
        best_column = None
        for column in range(columns):
            if board[column] == 0:
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0: 
                    #we dont ever get here
                    row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
                    score = (size + 1 - moves) / 2
                    if column > 0 and board[row * columns + column - 1] == mark:
                        score += 1
                    if (column < columns - 1 and board[row * columns + column + 1] == mark):
                        score += 1
                    if row > 0 and board[(row - 1) * columns + column] == mark:
                        score += 1
                    if row < rows - 2 and board[(row + 1) * columns + column] == mark:
                        score += 1
                else:
                    next_board = board[:]
                    play(next_board, column, mark, config)
                    (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -alpha, -beta)
                    score = score * -1     
                    
                    if score >= beta:                        
                        return (score, column)  # prune the exploration if we find a possible move better than what we were looking for.
                    if score > alpha:
                        alpha = score # reduce the [alpha;beta] window for next exploration, as we only                                               
                    
                if score > best_score:
                    best_score = score
                    best_column = column        
        return (best_score, best_column)
        #return (alpha, best_column)

    best_score, best_column = negamax(obs.board[:], obs.mark, max_depth, -size, size)        
    
    print(obs.mark, sum(1 if cell != 0 else 0 for cell in obs.board), best_score, best_column)
     
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
#board = obs.board
board = [0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 1, 1, 2, 0, 0, 0, 0, 1, 1, 1, 2, 0, 0, 0, 1, 2, 2, 1, 2, 0, 1, 2, 2, 2, 1, 2, 0]

[board[column] == 0 and is_win(board, column, mark, config, False) for column in range(columns)]

for column in range(columns):
    if board[column] == 0:
        next_board = board[:]
        play(next_board, column, mark, config)
        (score, _) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -size, size)
        score = score * -1   
        print(column, score)
    
best_score, best_column = negamax(obs.board[:], obs.mark, max_depth, -size, size)  

    
#%% Test
    
env.reset()
# Play as the first agent against default "random" agent.
#env.run([my_agent, "random"])
#env.run([my_agent, "negamax"])
#env.run([negamax_agent, "negamax"])
#env.run(["negamax", negamax_agent])
env.run([negamax_agent, negamax_agent])
#env.run(["negamax", negamax_agent])
#env.run([negamax_agent, "random"])
env.render()

#%% Profile
env.reset()
trainer = env.train([None, "random"])

observation = trainer.reset()

#is_win(observation.board, 2, observation.mark, env.configuration)
%timeit negamax_agent(observation, env.configuration)  
cProfile.run('negamax_agent(observation, env.configuration)  ')

#%% Debug
# Play as first position against random agent.
env.reset()
trainer = env.train([None, negamax_agent])
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

print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent, "random"], num_episodes=10)))
print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [negamax_agent, "negamax"], num_episodes=10)))
print("Negamax vs My Agent:", mean_reward(evaluate("connectx", ["negamax", negamax_agent], num_episodes=10)))
print("My Agent vs My Agent:", mean_reward(evaluate("connectx", [negamax_agent, negamax_agent], num_episodes=2)))

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
    