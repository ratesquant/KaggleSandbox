# -*- coding: utf-8 -*-
"""
Created on Mon Nov 30 12:31:20 2020

@author: chirokov
"""


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
from time import time
from random import choice

env = make("connectx", debug=True)
env.render()

#%%
#An Agent must return an action within 8 seconds (24 seconds on the first turn) of being invoked. If the Agent does not, it will lose the episode and may be invalidated 
        
#def negamax_agent(obs, config):
def negamax_agent(obs, config, debug_out):
    from random import choice  
    from time import time   
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board) 
    
    increment_depth = True if made_moves < 22 else False #uses iterative depth solver
    
    total_evals = 0
    
    max_evals = 100000 
    max_depth = 7 if made_moves < 14 else (8 if made_moves < 18 else  (9 if  made_moves<20 else (14 if made_moves<22 else 20) ))       
    #max_depth = max_depth if depth_override is None else depth_override
    #{made_moves :7 if made_moves < 14 else (8 if made_moves < 18 else  (9 if  made_moves<20 else (14 if made_moves<22 else 20) ))        for made_moves in range(25)}        
    
    debug_out['max_depth'] = max_depth
    
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
        return 0.1*score

    def play(board, column, mark, config):
        columns = config.columns
        rows = config.rows
        row = max([r for r in range(rows) if board[column + (r * columns)] == 0])
        board[column + (row * columns)] = mark
        return row
        
    def undo_play(board, column, row, mark, config):        
        board[column + (row *  config.columns)] = 0

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

        evals = 0
        # Tie Game
        if moves == size:
            return (0, None, evals)

        # Can win next.
        for column in column_order:
            if board[column] == 0 and is_win(board, column, mark, config, False):                
                return ((size + 1 - moves) / 2, column, evals)
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:               
                return (beta, None, evals)  # prune the exploration if the [alpha;beta] window is empty.                           

        # Recursively check all columns.        
        best_score = -size               
        best_column = None        
        for column in column_order: 
            if board[column] == 0:                
                # Max depth reached. Score based on cell proximity for a clustering effect.
                if depth <= 0:                                        
                    score = board_eval(board, moves, column, mark)                   
                    evals = evals + 1
                else:
                    #next_board = board[:]
                    #play(next_board, column, mark, config)
                    #(score, _, temp_evals) = negamax(next_board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)
                    
                    play_row = play(board, column, mark, config)
                    (score, _, temp_evals) = negamax(board, 1 if mark == 2 else 2, depth - 1, -beta, -alpha)                    
                    undo_play(board, column, play_row, mark, config)   
                    
                    evals = evals + temp_evals
                    score = score * -1            
                if score > best_score:
                    best_score = score
                    best_column = column                     
                alpha = max(alpha, score) # reduce the [alpha;beta] window for next exploration, as we only                                                                   
                #print("mark: %s, d:%s, col:%s, score:%s (%s, %s)) alpha = %s beta = %s" % (mark, depth, column, score,best_score, best_column, alpha, beta))            
                if alpha >= beta:                        
                #if alpha >= beta:                        
                    return (alpha, best_column, evals)  # prune the exploration if we find a possible move better than what we were looking for.                    
                    #print (alpha, best_column)  # prune the exploration if we find a possible move better than what we were looking for.                    
        return (alpha, best_column, evals)
    
    best_column = None
    best_score = None
    if made_moves == 0: #first move
        best_column = columns//2 #first move to the middle
    elif made_moves == 1: #second move
        prev_move = [c for c in range(columns) if obs.board[c + (rows - 1) * columns] != 0][0]        
        best_column = [3,2,3,3,3,4,3][prev_move] #second move    
    else:
        if increment_depth == True:             
             
             depth_start_time = time()
             
             time_limit = 7.0 #seconds
             my_depth = max_depth  
             
             debug_out['start_depth'] = max_depth
             debug_out['depth_log'] = dict()
        
             while True:
                 run_time_1 = time() 
                 best_score, best_column, temp_evals = negamax(obs.board[:], obs.mark, my_depth, -size, size)
                 total_evals = total_evals  + temp_evals
                 run_time_2 = time()                   
                 debug_out['depth_log'][my_depth] = (run_time_2 - depth_start_time, run_time_2 - run_time_1, best_score, best_column, temp_evals)                                      
                 if my_depth >= size - made_moves or abs(best_score)>=1:
                     break;
                 if time() - depth_start_time + 4*(run_time_2 - run_time_1) > time_limit: # check if we have enought time
                     break;
                 my_depth = my_depth + 1 # increment depth                                  
        else:            
            best_score, best_column, total_evals = negamax(obs.board[:], obs.mark, max_depth, -size, size)                    
            #print('mark: %d, moves: %d, best score %d, best move %d, total moves %d' % (obs.mark, made_moves, best_score, best_column, nodes))        
    debug_out['moves_made'] = made_moves
    debug_out['evals'] = total_evals
    debug_out['best_score'] = best_score
    debug_out['best_column'] = best_column    
     
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
#env.run([negamax_agent, negamax_agent])
env.render()

#%% Debug Negamax
    
from kaggle_environments.utils import structify
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
        mark = 1 if mark == 2 else 2
    return mark

def print_board(board):
    for r in range(rows):
        print('-'.join([str(board[c + (r * columns)]) for c in range(columns)]) )

mark = 1

moves = '44444343331156666656' #445264
moves = '4444434333115666665' #445264
moves = '424442414635262661' #445264, next move shoudl be 6
        
debug_out = dict()
board = columns * rows * [0]
mark = play_moves(moves, board, config)    
negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)
negamax_agent_ex(structify({'board':board, 'mark':mark}) , config)
negamax_agent(structify({'board':board, 'mark':mark}) , config, 8)
negamax_agent(structify({'board':board, 'mark':mark}) , config, 13)

#3.79 s ± 595 ms
%timeit negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)
cProfile.run("negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out) ")


print_board(board)
    
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

# position analyzer
# https://connect4.gamesolver.org/en/
moves = '4444233' #next should be 3 but algo picks 6
#moves = '444423366' #next should be 3 but algo picks 6
board = columns * rows * [0]
mark = play_moves(moves, board, config)    
print_board(board)

#negamax_agent(structify({'board':board, 'mark':mark}) , config)+1
negamax_agent_ex(structify({'board':board, 'mark':mark}) , config)+1



#%% Debug move
board = [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 2, 2, 0, 2, 1, 0, 0, 1, 1, 0, 2, 2, 0, 0, 1, 1, 2, 2, 2, 0, 0, 1, 1, 2, 1, 2, 0, 0]
negamax_agent(structify({'board':board, 'mark':1}) , config)


#%% Profile
#1.69 s ± 21.1 ms per loop 
env.reset()
trainer = env.train([None, "negamax"])

observation = trainer.reset()

my_action = negamax_agent_ex(observation, env.configuration)    
observation, reward, done, info = trainer.step(my_action)   

#is_win(observation.board, 2, observation.mark, env.configuration)
%timeit negamax_agent_ex(observation, env.configuration)  
cProfile.run('negamax_agent_ex(observation, env.configuration)  ')

#%% Debug
# Play as first position against random agent.
env.reset()
#trainer = env.train([None, negamax_agent])
trainer = env.train([None, "negamax"])
#trainer = env.train(["random", None])

observation = trainer.reset()

while not env.done:
    #my_action = my_agent(observation, env.configuration)    
    start_time = time.time()
    my_action = negamax_agent(observation, env.configuration)    
    observation, reward, done, info = trainer.step(my_action)    
    print("My Action[%d]: %s, %s [%s] %s sec" % (len(env.steps), my_action, reward, done, time.time() - start_time))
    #env.render(mode="ipython", width=100, height=90, header=False, controls=False)
env.render()

#%% Timing 

def get_timing(run_id, test_agent = "negamax"):        
    env.reset()
    #trainer = env.train([None, negamax_agent])
    #trainer = env.train([None, "negamax"])
    #trainer = env.train(["random", None])  
    #trainer = env.train([test_agent, None])    
    trainer = env.train([None, test_agent])    
    observation = trainer.reset()    
    result = list()    
    while not env.done:        
        start_time = time()
        debug_out = dict()
        my_action = negamax_agent(structify(observation), env.configuration, debug_out)    
        observation, reward, done, info = trainer.step(my_action)    
        if 'depth_log' in debug_out:
            res = debug_out['depth_log']
            min_d = min(res.keys())
            max_d = max(res.keys())                    
            result.append((run_id, test_agent, debug_out['moves_made'],debug_out['max_depth'], min_d, max_d,len(res), res[max_d][0], res[max_d][1], res[max_d][4],  time() - start_time, debug_out['best_score'], debug_out['best_column'], debug_out['evals'] ))     
        else:
            result.append((run_id, test_agent, debug_out['moves_made'],debug_out['max_depth'], None,None, None, None,None,None,  time() - start_time, debug_out['best_score'],debug_out['best_column'], debug_out['evals'] ))     
    return result
    
import pandas as pd
timing_results = list()
for i in range(20):       
    print(i)
    timing_results.extend(get_timing(i))
    #timing_results.extend(get_timing(i, "random"))    

res = pd.DataFrame(timing_results, columns = ['run_id', 'test_agent', 'moves','init_depth', 'min_depth', 'max_depth', 'depth_it', 'depth_time', 'depth_time2', 'depth_evals', 'elapsed', 'best_score', 'best_column', 'evals'])
res.to_csv(os.path.join(DATA_FOLDER, 'timing.csv'))      

#res.plot('move', 'elapsed')
  

#%% Evaluate
def mean_reward(rewards):
    return 100*sum(r[0] for r in rewards) /len(rewards)

# Run multiple episodes to estimate its performance.
#print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [my_agent, "random"], num_episodes=10)))
#print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [my_agent, "negamax"], num_episodes=10)))

#vs random
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent, "random"], num_episodes=10)))
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent_ex, "random"], num_episodes=10)))

#vs negamax
print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [negamax_agent,    "negamax"], num_episodes=10)))
print("My Agent vs Negamax Agent:", mean_reward(evaluate("connectx", [negamax_agent_ex, "negamax"], num_episodes=10)))

#vs each other
print("My Agent vs My AgentEx:", mean_reward(evaluate("connectx", [negamax_agent, negamax_agent_ex], num_episodes=3)))

    
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent, negamax_agent_ex], num_episodes=1)))
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent_submit, "random"], num_episodes=10)))
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [negamax_agent_iterative, "random"], num_episodes=10)))

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
DATA_FOLDER = 'D:/Github/KaggleSandbox/connect_x/submission/'

import inspect
import os

def write_agent_to_file(function, file):
    with open(file, "a" if os.path.exists(file) else "w") as f:
        f.write(inspect.getsource(function))
        print(function, "written to", file)

write_agent_to_file(negamax_agent, DATA_FOLDER + "submission_it_v6.py")
write_agent_to_file(negamax_agent_ex, DATA_FOLDER + "submission_it_ex.py")

#%% Validate

import sys
out = sys.stdout
#submission = utils.read_file(DATA_FOLDER + "submission_7.py")
submission = utils.read_file(DATA_FOLDER + "submission_it_v6.py")
#submission = utils.read_file(DATA_FOLDER + "submission_it_plus.py")
agent = utils.get_last_callable(submission)
sys.stdout = out

env = make("connectx", debug=True)
env.run([agent, agent])
print("Success!" if env.state[0].status == env.state[1].status == "DONE" else "Failed...")
    
