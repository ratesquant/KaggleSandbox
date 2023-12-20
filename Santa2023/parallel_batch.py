# -*- coding: utf-8 -*-
"""
Created on Tue Dec 19 22:12:40 2023

@author: chirokov
"""

#%% parallel random search
from multiprocessing import Pool

import pandas as pd
import random
import os
from ast import literal_eval
from sympy.combinatorics import Permutation
from time import time
from math import log
import argparse

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
    #initial_state_str = ''.join(initial_state)
    for i in range(it_count):
        #all_states = set([initial_state_str])
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
  
def random_solve_wrapper(params):
    allowed_moves = {k: Permutation(v) for k, v in  params['allowed_moves'].items()}
    new_moves = random_solve(params['initial_state'], params['final_state'],  allowed_moves, params['max_moves'], params['max_it'])    
    return new_moves

if __name__ == '__main__':    
    #%% parse input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("-max_it", help="maximum number of iterations", type=int)
    parser.add_argument("-threads", help="maximum number of threads", type=int)
    args = parser.parse_args()
    print(args)
    
    #%% Load Data
    data_folder = 'D:/Github/KaggleSandbox/Santa2023/data'

    puzzle_info = pd.read_csv(os.path.join(data_folder, 'puzzle_info.csv'), index_col='puzzle_type')
    puzzles = pd.read_csv(os.path.join(data_folder, 'puzzles.csv'), index_col='id')
    sample_submission = pd.read_csv(os.path.join(data_folder, 'sample_submission.csv'))
    solution_submission = pd.read_csv(os.path.join(data_folder, 'solution_submission_random_batch.csv'), index_col='id')

    all_allowed_moves = {}
    for index, row in puzzle_info.iterrows():        
        allowed_moves = literal_eval(row['allowed_moves'])
        allowed_moves = {k: Permutation(v) for k, v in allowed_moves.items()}
        allowed_moves_inv = {'-%s' % k: Permutation(v)**(-1) for k, v in allowed_moves.items()}
        allowed_moves.update(allowed_moves_inv)
        all_allowed_moves[index] = allowed_moves

    print('Random Check: %s' % random.choices(list(range(100)), k = 10))

    max_it = args.max_it# 1000000
    input_params = []
    for index, row in solution_submission.iterrows():    
        my_type = puzzles.loc[index].puzzle_type
        final_state=puzzles.loc[index].solution_state.split(';')
        initial_state=puzzles.loc[index].initial_state.split(';')        
        allowed_moves = all_allowed_moves[my_type]        
        moves = solution_submission.loc[index].moves.split('.')      
        
        allowed_moves = {k:v(range(v.size)) for k, v in allowed_moves.items()} #convert permutations to index to that pickle works
        
        input_params.append({'index': index, 'my_type':my_type,'initial_state':initial_state,'final_state':final_state, 'allowed_moves':allowed_moves, 'prev_moves':moves, 'max_moves':len(moves), 'max_it': max_it // len(moves)})

    print('Starting batch calc with %d jobs, maxit: %d' % (len(input_params), max_it))
    
    start_time = time()

    #import pickle
    #pickled = pickle.dumps(input_params[1])    
    #pickled = pickle.dumps(Permutation([0, 1,2,3]))    
    #unpickled = pickle.loads(pickled)
    #exit(0) 

    calc_results = None
    with Pool(args.threads) as p:
        calc_results = list(p.map(random_solve_wrapper, input_params))
    #calc_results = list(map(random_solve_wrapper, input_params))
    
    print('Batch is done in %.1f min, using %d threads' % ( (time() - start_time)/60, args.threads ))
        
    #process results
    updated_index = []
    for job_output, job_input in zip(calc_results, input_params):
        new_moves = job_output 
        if new_moves is not None:   
            initial_state = job_input['initial_state']
            final_state = job_input['final_state']
            allowed_moves = job_input['allowed_moves']
            moves =  job_input['prev_moves']
            index =  job_input['index']
            my_type =  job_input['my_type']
            
            allowed_moves = {k: Permutation(v) for k, v in  allowed_moves.items()}
            
            new_moves = check_moves(initial_state, new_moves, allowed_moves)
            if len(new_moves) < len(moves):        
                state = apply_moves(initial_state,new_moves, allowed_moves)                        
                if state==final_state:
                    updated_index.append(index)
                    solution_submission.loc[index].moves = '.'.join(new_moves)           
                    print('%d %s, moves: %s,new moves: %s, improved: %s' % (index, my_type,  len(moves), len(new_moves), len(new_moves)<len(moves) ))
    
    print('Check updates: %d' % ( len(updated_index) ))
    #check updated moves
    for index in updated_index:
        start_time = time()
        moves = solution_submission.loc[index].moves.split('.')        
        my_id = puzzles.index[index]
        my_type = puzzles.loc[index].puzzle_type
        final_state=puzzles.loc[index].solution_state.split(';')
        initial_state=puzzles.loc[index].initial_state.split(';')        
        allowed_moves = all_allowed_moves[my_type]    
        state = apply_moves(initial_state,moves, allowed_moves)    
        unique_states = check_unique_states(initial_state, moves, allowed_moves)
        print('%s, %s, moves: %d, allowed: %d, %s, unique : %s (%.1f sec)' % (my_id, my_type, len(moves), len(allowed_moves), state == final_state, unique_states == 1, time()-start_time) )

    
    outputfile = os.path.join(data_folder, 'solution_submission_random_batch.csv')
    print('Saved results to the %s' % outputfile)
    solution_submission.to_csv(outputfile)   
