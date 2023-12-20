# -*- coding: utf-8 -*-
"""
Created on Mon Dec 18 21:31:17 2023

@author: chirokov
"""

import pandas as pd
import random
import os
from ast import literal_eval
from sympy.combinatorics import Permutation
from time import time

#%% Load Data
data_folder = 'D:/Github/KaggleSandbox/Santa2023/data'

puzzle_info = pd.read_csv(os.path.join(data_folder, 'puzzle_info.csv'), index_col='puzzle_type')
puzzles = pd.read_csv(os.path.join(data_folder, 'puzzles.csv'), index_col='id')
sample_submission = pd.read_csv(os.path.join(data_folder, 'sample_submission.csv'))
solution_submission = pd.read_csv(os.path.join(data_folder, 'solution_submission_v1.csv'), index_col='id')

all_allowed_moves = {}
for index, row in puzzle_info.iterrows():        
    allowed_moves = literal_eval(row['allowed_moves'])
    allowed_moves = {k: Permutation(v) for k, v in allowed_moves.items()}
    allowed_moves_inv = {'-%s' % k: Permutation(v)**(-1) for k, v in allowed_moves.items()}
    allowed_moves.update(allowed_moves_inv)
    all_allowed_moves[index] = allowed_moves

#%% Benchmark permutation application
index = 1
my_type = puzzles.loc[index].puzzle_type
final_state=puzzles.loc[index].solution_state.split(';')
initial_state=puzzles.loc[index].initial_state.split(';') 
allowed_moves = all_allowed_moves[my_type]  
random.seed(123456789)
move_vector = random.choices(list(allowed_moves.keys()), k = 100)

#152 µs ± 1.36 µs per loop (mean ± std. dev. of 7 runs, 10,000 loops each)
%timeit apply_moves(initial_state,move_vector, allowed_moves)      

#1.56 µs ± 25.9 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)
state = ''.join(initial_state)
%timeit allowed_moves['f0'](state)

pindex = [i^allowed_moves['f0'] for i in range(allowed_moves['f0'].size)]
%timeit ''.join([state[i] for i in pindex])
%timeit ''.join(allowed_moves['f0'](state))
%timeit ''.join(allowed_moves['f0'](initial_state))


#%% functions
def check_moves(initial_state, moves, allowed_moves):
    state = initial_state[:]
    state_str =  ''.join(state)
    state_v = [state_str]
    valid_moves = [True] * len(moves)
    for i, move in enumerate(moves):
        state = allowed_moves[move](state)
        state_str =  ''.join(state)
        #print('%s %sm %s' % (i, move, state_str))
        state_v.append(state_str)
        if state_str in state_v:
            matching_index = state_v.index(state_str)
            for k in range(matching_index, i+1):
                valid_moves[k] = False
                state_v[k+1] = '--XXXXXXXX--'        
    return [move for i, move in enumerate(moves) if valid_moves[i]]

def check_unique_states(initial_state, moves, allowed_moves):
    state = initial_state[:]
    state_str =  ''.join(state)
    state_v = set([state_str])    
    for i, move in enumerate(moves):
        state = allowed_moves[move](state)        
        state_v.add(''.join(state))        
    return len(state_v) - len(moves)

def apply_moves_fast(initial_state, moves, allowed_moves):
    state = initial_state
    for move in moves:
        state = allowed_moves[move](state)
    return state

def apply_moves(initial_state, moves, allowed_moves):
    state = initial_state[:]
    for move in moves:
        state = allowed_moves[move](state)
    return state

def random_solve(initial_state, final_state, allowed_moves, max_moves, it_count):
    best_solution = None
    possible_moves = list(allowed_moves.keys())
    final_state_str = ''.join(final_state)
    initial_state_str = ''.join(initial_state)
    for i in range(it_count):
        all_states = set([initial_state_str])
        move_vector = random.choices(possible_moves, k = max_moves)
        my_state = initial_state[:]     
        for k, move in enumerate(move_vector):         
            my_state = allowed_moves[move](my_state) 
            my_state_str = ''.join(my_state)
            #if my_state_str in all_states:
            #    break
            #all_states.add(my_state_str)
            if my_state_str == final_state_str:
                if best_solution is None:
                    best_solution = move_vector[:(k+1)]                    
                if len(best_solution)>k+1:
                    best_solution = move_vector[:(k+1)]
                    max_moves = len(best_solution) - 1
                    if max_moves == 0:
                        return best_solution                        
    return best_solution
                
def solve_puzzle(initial_state, final_state, allowed_moves, moves, depth, max_depth):
    best_solution = None
    for move_name, move in allowed_moves.items():         
        my_state = move(initial_state)        
        current_moves = moves + [move_name]
        #print('%d: %d %s %s %s, prev state: %d' % (depth, len(current_moves), '.'.join(current_moves), ''.join(initial_state),  ''.join(my_state), len(previous_states) ))      
        if len(moves) >= max_depth: 
            return (current_moves, False)
        if my_state == final_state:
            #print ('Solution found: %s' % '.'.join(moves))
            return (current_moves, True)
        else:
            res = solve_puzzle(my_state, final_state, allowed_moves, current_moves, depth + 1, max_depth)                                        
            if best_solution is None:
                best_solution = res                
            if res[1] and len(best_solution[0]) > len(res[0]):
                best_solution = res                    
    return (best_solution)        
        
def solve_puzzle_ex(initial_state, final_state, allowed_moves, moves, depth, max_depth, previous_states):
    best_solution = None
    for move_name, move in allowed_moves.items():         
        my_state = move(initial_state)        
        current_moves = moves + [move_name]
        #print('%d: %d %s %s %s, prev state: %d' % (depth, len(current_moves), '.'.join(current_moves), ''.join(initial_state),  ''.join(my_state), len(previous_states) ))
        my_state_str = ''.join(my_state)
        if my_state_str in previous_states:
            return (current_moves, False)            
        if len(moves) >= max_depth: 
            return (current_moves, False)
        if my_state == final_state:
            #print ('Solution found: %s' % '.'.join(moves))
            return (current_moves, True)
        else:
            pstates = previous_states.copy()
            pstates.add(my_state_str)
            res = solve_puzzle_ex(my_state, final_state, allowed_moves, current_moves, depth + 1, max_depth, pstates)                                        
            if best_solution is None:
                best_solution = res                
            if res[1] and len(best_solution[0]) > len(res[0]):
                best_solution = res                    
    return (best_solution)
#solve_puzzle_ex(initial_state, new_state, allowed_moves, [], 0, 2, set())  
#%% Checks
final_state=puzzles.loc[0].solution_state.split(';')
initial_state=puzzles.loc[0].initial_state.split(';')

puzzle_type = 'cube_2/2/2'
allowed_moves = all_allowed_moves[puzzle_type]
moves = solution_submission.loc[1].moves.split('.')

solution = solve_puzzle(initial_state, final_state, allowed_moves, [], 0, 2)

state = apply_moves(initial_state,['r1','-f1'], allowed_moves)

''.join(initial_state)
''.join(state)

#%% Check all solutions 
for index, row in solution_submission.iterrows():
    start_time = time()
    moves = row['moves'].split('.')        
    my_id = puzzles.index[index]
    my_type = puzzles.loc[index].puzzle_type
    final_state=puzzles.loc[index].solution_state.split(';')
    initial_state=puzzles.loc[index].initial_state.split(';')        
    allowed_moves = all_allowed_moves[my_type]    
    state = apply_moves(initial_state,moves, allowed_moves)    
    unique_states = check_unique_states(initial_state, moves, allowed_moves)
    print('%s, %s, moves: %d, allowed: %d, %s, unique : %s (%.1f sec)' % (my_id, my_type, len(moves), len(allowed_moves), state == final_state, unique_states == 1, time()-start_time) )

solution_submission.to_csv(os.path.join(data_folder, 'solution_submission_v1.csv'))
#%% Check solution for loops (152) 
for index, row in solution_submission.iterrows():    
    #moves = solution_submission.loc[index].moves.split('.')
    moves = row['moves'].split('.')        
    my_id = index
    my_type = puzzles.loc[index].puzzle_type
    final_state=puzzles.loc[index].solution_state.split(';')
    initial_state=puzzles.loc[index].initial_state.split(';')        
    allowed_moves = all_allowed_moves[my_type]    
    
    state = apply_moves(initial_state,moves, allowed_moves)        
    print('id: %s, moves: %s valid: %s' % (index, len(moves), state==final_state))
    
    new_moves = check_moves(initial_state, moves, allowed_moves)
    if len(new_moves) < len(moves):        
        state = apply_moves(initial_state,new_moves, allowed_moves)        
        print('id: %s, moves: %s valid: %s (new moves)' % (index, len(new_moves), state==final_state))
        if state==final_state:
            solution_submission.loc[index].moves = '.'.join(new_moves)
        
    if index > 24:
        break

solution_submission.to_csv(os.path.join(data_folder, 'solution_submission_v1.csv'))

#%% Random Search
max_it = 10000000
for index, row in solution_submission.iterrows():    
    start_time = time()
    #if index > 29:
    #    break
    #index = 3
    my_type = puzzles.loc[index].puzzle_type
    final_state=puzzles.loc[index].solution_state.split(';')
    initial_state=puzzles.loc[index].initial_state.split(';')        
    allowed_moves = all_allowed_moves[my_type]    
    
    moves = solution_submission.loc[index].moves.split('.')
       
    #%timeit random_solve(initial_state, final_state,  all_allowed_moves[my_type], 100, 100)    
    new_moves = random_solve(initial_state, final_state,  allowed_moves, len(moves), max_it // len(moves))    
    if new_moves is not None:   
        new_moves = check_moves(initial_state, new_moves, allowed_moves)
        if len(new_moves) < len(moves):        
            state = apply_moves(initial_state,new_moves, allowed_moves)        
            print('id: %s, moves: %s valid: %s (new moves)' % (index, len(new_moves), state==final_state))
            if state==final_state:
                solution_submission.loc[index].moves = '.'.join(new_moves)           
    print('%d %s, moves: %s, improved: %s (%.1f sec)' % (index, my_type,  len(moves), new_moves is not None and len(new_moves)<len(moves), time()-start_time ))
    
    
solution_submission.to_csv(os.path.join(data_folder, 'solution_submission_random.csv'))    

#%% Check all possibilities up to specified number of moves
my_types = set(['cube_19/19/19', 'cube_33/33/33', 'cube_10/10/10', 'cube_9/9/9', 'cube_8/8/8', 'cube_5/5/5', 'cube_6/6/6', 'globe_3/33', 'globe_33/3', 'globe_8/25'])
my_deep_types = set(['wreath_6/6', 'wreath_7/7', 'wreath_12/12', 'wreath_21/21', 'wreath_100/100'])
for index, row in solution_submission.iterrows():    
    start_time = time()
    my_type = puzzles.loc[index].puzzle_type
    final_state=puzzles.loc[index].solution_state.split(';')
    initial_state=puzzles.loc[index].initial_state.split(';')        
    allowed_moves = all_allowed_moves[my_type]    
    
    #if my_type in my_types:
    if my_type not in my_deep_types:        
        continue
    
    moves = solution_submission.loc[index].moves.split('.')    
    
    new_moves, moves_found = solve_puzzle_ex(initial_state, final_state, allowed_moves, [], 0, 22, set())
            
    if moves_found and new_moves is not None and len(new_moves) < len(moves):        
        state = apply_moves(initial_state,new_moves, allowed_moves)        
        print('id: %s, moves: %s valid: %s (new moves)' % (index, len(new_moves), state==final_state))
        if state==final_state:
            solution_submission.loc[index].moves = '.'.join(new_moves)
            print('%d %s, moves: %s, improved: %s (%.1f sec)' % (index, my_type,  len(moves), new_moves is not None and len(new_moves)<len(moves), time()-start_time ))

    print('%d %s moves: %s time (%.1f)' % (index, my_type, len(moves), time()-start_time ))   

solution_submission.to_csv(os.path.join(data_folder, 'solution_submission_all.csv'))    


#%% Check Score
sum([len(move_list.split('.')) for move_list in sample_submission.moves]) # 1220590
sum([len(move_list.split('.')) for move_list in solution_submission.moves]) #1201015


#%% Random Search
found_moves = {}
for index, row in puzzles.iterrows():  
    #index = 3
    my_type = row['puzzle_type']
    final_state=row['solution_state'].split(';')
    initial_state=row['initial_state'].split(';')    
    
    #%timeit random_solve(initial_state, final_state,  all_allowed_moves[my_type], 100, 100)
    
    res = random_solve(initial_state, final_state,  all_allowed_moves[my_type], 100, 1000000)
    moves = "None" if res is None else '.'.join(res)
    found_moves[index] = moves
    
    print('%d %s moves: %s' % (index, my_type,  moves ))   

with open('D:/Github/KaggleSandbox/Santa2023/data/found_moves.txt', 'wt') as f:
    f.write('%s'% found_moves)

#%% Test Solver
index = 0
my_type = puzzles.loc[index].puzzle_type
final_state=puzzles.loc[index].solution_state.split(';')
initial_state=puzzles.loc[index].initial_state.split(';') 
allowed_moves = all_allowed_moves[my_type]    
#move_vector = random.choices(list(allowed_moves.keys()), k = 5)
#new_state = apply_moves(initial_state,move_vector, allowed_moves)      

#r1.-f1, 171 ms ± 2.18 ms per loop (mean ± std. dev. of 7 runs, 10 loops each)
%timeit solve_puzzle_ex(initial_state, final_state, allowed_moves, [], 0, 5, set([]))
%timeit solve_puzzle   (initial_state, final_state, allowed_moves, [], 0, 5)

