#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Jan 11 16:27:39 2020
"""
#pip install 'kaggle-environments>=0.1.6'
import os
import cProfile
import json
from kaggle_environments import evaluate, make, utils
import numpy as np
from time import time
from random import choice

#DATA_FOLDER = os.getenv('HOME') + '/source/github/KaggleSandbox/connect_x/' 
DATA_FOLDER = 'D:/Github/KaggleSandbox/connect_x/submission/'

env = make("connectx", debug=True)
#env.render()

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
        mark = 3 - mark
    return mark

def print_board(board):
    for r in range(rows):
        print('-'.join([str(board[c + (r * columns)]) for c in range(columns)]) )


#timing 2 sec per turn + 60 sec or exceedance total (2.5)
# on average 4.5 /sec

#%%
#An Agent must return an action within 8 seconds (24 seconds on the first turn) of being invoked. If the Agent does not, it will lose the episode and may be invalidated 

debut_hashtable = {7551510705482241731: 3, 522120584338709296: 3, -1240559124920122598: 2, 3945848622772750764: 3, 2015441730067367180: 3, -5064514122604784884: 3, 7551529572239210266: 4, 7551510705486626776: 3, 6403405561489853926: 3, 2878046142972190138: 1, -5195882435351614754: 5, 170665929465627438: 3, -4769863852397134434: 1, 2015403996553430110: 1, 2015441730076137270: 3, -7442728726238249925: 3, 1939584291861271111: 3, -6944355283781548839: 3, -6636997061359620615: 3, 2066007461595986809: 3, 7896707840461543275: 3, 7896726707214126765: 2, -1921229493549496057: 2, 5218075775768867211: 1, -7920070485840169229: 2, -6939910057795817729: 3, 140045794876334335: 2, 5970746173741890801: 2, 5970765040494474291: 2, -5009503165090434145: 3, 5503547797637329605: 2, 8386018973915889533: 3, 5489735500030028277: 3, -7126308194813966873: 3, -7126289328061383383: 3, 4213413759151844105: 3, 2450734049893012211: 2, 7637141797585885573: 1, 867522827516547439: 3, -5660053316156897563: 2, 170647062708658903: 4, 170665929461242393: 3, 4000859580287101503: 3, -1050362354416126435: 4, -2868312441804999713: 4, 2310073133518049095: 3, 2310092000270632585: 3, -6263203864882760853: 1, 5544727590787410481: 4, -2839475826448719385: 4, -4769882719154102969: 3, -1324444431304690735: 4, -1445310320671913829: 5, 766223989770323607: 4, -8615165247804310157: 3, 4780356891202013521: 3, -3520608378594923881: 3, 2989904108280006673: 3}
        
#def negamax_agent(obs, config):
#    debug_out = dict()
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
                    (score, _, temp_evals) = negamax(board, 3 - mark, depth - 1, -beta, -alpha)                    
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
    elif made_moves == 1 and columns == 7: #second move
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

#def negamax_agent_ex(obs, config):    
#    debug_out = dict()
#position_table = {}
DEBUG = True
def negamax_agent_ex(obs, config):    
    from random import choice  
    from time import time     
    
    #global position_table
    position_table = {}
    win_table = {}
    
    total_time = time() 
  
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board)     
    
    increment_depth = True #uses iterative depth solver
    
    total_evals = 0    
    
    max_depth = 4
    #max_depth = 7 if made_moves < 14 else (8 if made_moves < 18 else  (9 if made_moves < 20 else (14 if made_moves < 22 else 20) ))       
    #max_depth = max_depth if depth_override is None else depth_override
    #{made_moves :7 if made_moves < 14 else (8 if made_moves < 18 else  (9 if  made_moves<20 else (14 if made_moves<22 else 20) ))       for made_moves in range(25)}        

    if DEBUG:
        obs.debug = {}    
        obs.debug['max_depth'] = max_depth    
    
    
    #v1 of the evaluation function
    def board_eval_ex_v1(board, moves, row, column, mark, config):        
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1  
        inv_mark = 3 - mark
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                    return i - 1
            return inarow
        score = 0 
        
        if  count(1, 0) + count(-1, 0) >= inarow:
            score += 1            
        if  count(0, 1) + count(0, -1) >= inarow:
            score += 1
        if  count(-1, -1) + count(1, 1) >= inarow:
            score += 1
        if  count(-1, 1) + count(1, -1) >= inarow:
            score += 1    
        return 0.1*score
    
    #v3 of the evaluation function
    def board_eval_ex_v2(board, moves, row, column, mark, config):        
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1  
        inv_mark = 3 - mark
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                    return i - 1
            return inarow
        score = 0
        score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)           
        score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow)           
        score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
        score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
        return 0.01*score
    
    def board_eval_ex_v3(board, moves, row, column, mark):        
        def board_eval_internal(board, moves, row, column, mark):        
            inarow = config.inarow - 1  
            inv_mark = 3 - mark        
        
            def count(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or c < 0 or r >= rows or c >= columns or board[c + (r * columns)] == inv_mark):
                        return i - 1
                return inarow
            score = 0
            score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)           
            score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow)           
            score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
            score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
            return score
    
        inv_mark = 3 - mark       
        score = 0

        for index in range(size):
            if board[index] != 0: 
                r = index // columns
                c = index %  columns
                if board[index] == mark:                
                    score += board_eval_internal(board, moves, r, c, mark)       
                else:# board[index] == inv_mark:
                    score -= board_eval_internal(board, moves, r, c, inv_mark)                
        
        return 0.01*score  
    
    #eval v4 - counts possibilities
    def board_eval_ex_v4(board, moves, row, column, mark, config):        
        def board_eval_ex4_internal(board, moves, row, column, mark, config):        
            inarow = config.inarow - 1  
            inv_mark = 3 - mark         
        
            def count(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                        return i - 1
                return inarow
            
            def count_act(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                        return i - 1
                return inarow
            score = 0
            score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow) * (count_act( 1,  0) + count_act(-1,  0))           
            score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow) * (count_act( 0,  1) + count_act( 0, -1))        
            score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow) * (count_act(-1, -1) + count_act( 1,  1))
            score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow) * (count_act(-1,  1) + count_act( 1, -1)) 
            return score 
        
        inv_mark = 3 - mark          
        score = board_eval_ex4_internal(board, moves, row, column, mark, config)
        for r in range(rows):      
            for c in range(columns):
                if board[c + (r * columns)] == mark:
                    score += board_eval_ex4_internal(board, moves, r, c, mark, config)            
                elif board[c + (r * columns)] == inv_mark:
                    score -= board_eval_ex4_internal(board, moves, r, c, inv_mark, config)                                
        return 0.01*score
    
    def board_eval_ex_v5(board, moves, row, column, mark, config):        
        def board_eval_ex5_internal(board, moves, row, column, mark, config):        
            inarow = config.inarow - 1  
            inv_mark = 3 - mark             
            
            def count(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                        return i - 1
                return inarow
            score = 0
            score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)
            score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow) 
            score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)
            score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)
            return score 
        
        inv_mark = 3 - mark          
        score = 0
        board[column + (row * columns)] = mark
        for r in range(rows):      
            for c in range(columns):
                if board[c + (r * columns)] == 0:
                    score += board_eval_ex5_internal(board, moves, r, c, mark,     config)                        
                    score -= board_eval_ex5_internal(board, moves, r, c, inv_mark, config)                                
        board[column + (row * columns)]  = 0
        return 0.01*score
    
    #same as v5
    def board_eval_ex_v6(board, moves, row, column, mark, config):        
        def board_eval_ex6_internal(board, moves, row, column, mark, config):        
            inarow = config.inarow - 1  
            inv_mark = 3 - mark             
            
            def count(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] != mark):
                        return i - 1
                return inarow
            score = 0
            score += max(0, count( 1,  0) + count(-1,  0) - 2)
            score += max(0, count( 0,  1) + count( 0, -1) - 2)
            score += max(0, count(-1, -1) + count( 1,  1) - 2)
            score += max(0, count(-1,  1) + count( 1, -1) - 2)
            return score 
        
        inv_mark = 3 - mark          
        score = 0        
        for index in range(size):
            if board[index] == 0:
                r = index // columns
                c = index %  columns
                score += board_eval_ex6_internal(board, moves, r, c, mark,     config)                        
                score -= board_eval_ex6_internal(board, moves, r, c, inv_mark, config) 
        return 0.01*score



    def is_win(board, row, column, mark):
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
    
    def get_move_row(board, column):        
        for r in range(rows-1, 0, -1):
            if board[column + (r * columns)] == 0:
                return r
        return 0             

    #alpha = minimum score that the maximizing player is assured of
    #beta the maximum score that the minimizing player is assured of
    def negamax(board, mark, depth, alpha, beta, moves, is_root = False):                         
        board_keys =  [0] * columns
        rows_cache = [0] * columns
        evals = 0
        # Tie Game
        if moves == size:
            return (0, None, evals)        

        # Can win next.
        for column in column_order:
            if board[column] == 0:
                row = get_move_row(board, column)
                rows_cache[column] = row
                
                index = column + (row * columns)
                
                board[index] = mark
                board_key = hash(tuple(board)) 
                board[index] = 0         
                
                if board_key in win_table:
                    is_win_res = win_table[board_key]
                else:
                    is_win_res = is_win(board, row, column, mark)
                    win_table[board_key] = is_win_res
                
                board_keys[column] = board_key
                
                evals += 1 
                if is_win_res:
                    return ((size + 1 - moves) // 2, column, evals)
                #rows_cache[column] = row            
            
        max_score = (size - 1 - moves) // 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:                
                return (beta, None, evals)  # prune the exploration if the [alpha;beta] window is empty.                             
        

        # Recursively check all columns.        
        best_score = -size               
        best_column = None        
        for column in column_order: 
            if board[column] == 0:
                row  = rows_cache[column]                  
                index = column + (row * columns)
                if depth <= 0:
                    board[index] = mark
                    board_key = board_keys[column] 
                    if board_key in position_table:
                        score = position_table[board_key]
                    else:
                        #score = board_eval_ex_v6(board, moves, row, column, mark, config) 
                        score = board_eval_ex_v3(board, moves, row, column, mark) 
                        position_table[board_key] = score
                        evals += 1
                    board[index] = 0
                else:                                        
                    board[index] = mark #play
                    (score, _, temp_evals) = negamax(board, 3 - mark, depth - 1, -beta, -alpha, moves + 1)                                                              
                    board[index] = 0 #undo play                    
                    evals += temp_evals
                    score = score * -1                
                # if is_root:
                #     print('col:%s, score:%s, alpha:%s, beta:%s, depth:%s' % (column, score, alpha, beta, depth))
                if score > best_score:
                    best_score = score
                    best_column = column                     
                alpha = max(alpha, score)
                if alpha >= beta:                                        
                    break #return beta or best score            
        return (alpha, best_column, evals) #Fail-Hard
    
    best_column = None
    best_score = None
    if made_moves == 0: #first move
        best_column = columns//2 #first move to the middle
    elif made_moves <=3 and columns == 7 and rows == 6 and hash(tuple(obs.board)) in debut_hashtable: #second move        
        best_column =  debut_hashtable[hash(tuple(obs.board))]  - 1
    elif increment_depth == True:             
        depth_start_time = time()
        
        time_limit = 10.0 #seconds
        my_depth = max_depth  
        
        if DEBUG:
            obs.debug['start_depth'] = max_depth
            obs.debug['depth_log'] = dict()                          
         
        while True:                     
            run_time_1 = time() 
            best_score, best_column, temp_evals = negamax(obs.board[:], obs.mark, my_depth, -size, size, made_moves, True)            
            #best_score, best_column, temp_evals = negamax(obs.board[:], obs.mark, my_depth, -1, 1, made_moves)            
            #print('depth: %d, alpha: %f, beta: %f, best score %f' % (my_depth, my_alpha, my_beta, best_score))
            total_evals = total_evals  + temp_evals
            run_time_2 = time()       
            if DEBUG:            
                obs.debug['depth_log'][my_depth] = (run_time_2 - depth_start_time, run_time_2 - run_time_1, best_score, best_column, temp_evals)                                                      
            if my_depth >= size - made_moves or abs(best_score)>=1:
                break
            if time() - depth_start_time + 4*(run_time_2 - run_time_1) > time_limit: # check if we have enought time
                break
            my_depth = my_depth + 1 # increment depth                                  
        else:            
            best_score, best_column, total_evals = negamax(obs.board[:], obs.mark, max_depth, -size, size, made_moves, True)                    
            
    if DEBUG:
        obs.debug['moves_made'] = made_moves
        obs.debug['evals'] = total_evals
        obs.debug['best_score'] = best_score
        obs.debug['best_column'] = best_column  
        obs.debug['total_time'] = time()  - total_time
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])    
    return best_column
#negamax_agent_ex
#get_win_percentages(negamax_agent_ex, 'negamax', 10)
 

#with random move revaluation ----
#def negamax_agent_hybrid(obs, config):    
#    debug_out = dict()
def negamax_agent_hybrid(obs, config, debug_out):    
    from random import choice
    from random import random
    from time import time    
    from numpy import argsort
 
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board)         
    
    
    total_evals = 0    
    
    max_depth = 6 
    #max_depth = max_depth if depth_override is None else depth_override
    #{made_moves :7 if made_moves < 14 else (8 if made_moves < 18 else  (9 if  made_moves<20 else (14 if made_moves<22 else 20) ))       for made_moves in range(25)}        
    
    debug_out['max_depth'] = max_depth
    
    #v1 of the evaluation function
    def board_eval_ex_v1(board, moves, row, column, mark, config):        
        columns = config.columns
        rows = config.rows
        inarow = config.inarow - 1  
        inv_mark = 3 - mark
    
        def count(offset_row, offset_column):
            for i in range(1, inarow + 1):
                r = row + offset_row * i
                c = column + offset_column * i
                if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                    return i - 1
            return inarow
        score = 0 
        
        if  count(1, 0) + count(-1, 0) >= inarow:
            score += 1            
        if  count(0, 1) + count(0, -1) >= inarow:
            score += 1
        if  count(-1, -1) + count(1, 1) >= inarow:
            score += 1
        if  count(-1, 1) + count(1, -1) >= inarow:
            score += 1    
        return 0.1*score


    def is_win(board, row, column, mark, config):
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
    
    def get_move_row(board, column, config):        
        columns = config.columns
        rows = config.rows
        for r in range(rows-1, 0, -1):
            if board[column + (r * columns)] == 0:
                return r
        return 0  

    def play_random_game(board, mark, config):        
        columns = config.columns        
        for column in range(columns):
            if board[column] == 0:
                row = get_move_row(board, column, config)                
                if is_win(board, row, column, mark, config):
                    return mark
        #choose the random position if we can win 
        possible_moves = [c for c in range(columns) if board[c] == 0]
        if len(possible_moves) == 0:
            return 0 # tie
        column = choice(possible_moves)
        row = get_move_row(board, column, config)                
        board[column + (row * columns)] = mark        
        return play_random_game(board, 3 - mark , config)    

    def random_board_eval(board, mark, n_rounds = 100):        
        columns = config.columns
        rows = config.rows
        size = rows * columns   
        
        my_board = board[:]     
        scores = [0] * columns
        
        for column in range(columns):
            if my_board[column] == 0:
                row = get_move_row(my_board, column, config)                
                if is_win(my_board, row, column, mark, config):
                    scores[column]  = float('Inf')
                    break
                else:
                    my_board[column + (row * columns)] = mark #play
                    outcome = [play_random_game(my_board[:], 3 - mark, config) for  i in range(n_rounds)] 
                    outcome = [1 if m == mark else ( 0 if m == 0 else -1) for m in outcome ]
                    my_board[column + (row *  columns)] = 0 #undo play    
                    #print('%d %f' % (column, sum(outcome)/len(outcome)))
                    scores[column] = sum(outcome)
        return scores
        

    #alpha = minimum score that the maximizing player is assured of
    #beta the maximum score that the minimizing player is assured of
    def negamax(board, mark, depth, alpha, beta, moves, specified_column_order = None):                         
        #if moves != sum(1 if cell != 0 else 0 for cell in board):
        #    print('move count does not match')
        
        rows_cache = [0] * columns

        evals = 0
        # Tie Game
        if moves == size:
            return (0, None, evals)   
        
        my_column_order = column_order if specified_column_order is None else specified_column_order

        # Can win next.
        for column in my_column_order:
            if board[column] == 0:
                row = get_move_row(board, column, config)  
                evals += 1 
                if is_win(board, row, column, mark, config):
                    return ((size + 1 - moves) / 2, column, evals)
                rows_cache[column] = row
            
        max_score = (size - 1 - moves) / 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:                
                return (beta, None, evals)  # prune the exploration if the [alpha;beta] window is empty.                           

        # Recursively check all columns.        
        best_score = -size               
        best_column = None        
        for column in my_column_order: 
            if board[column] == 0:
                row  = rows_cache[column]                            
                if depth <= 0:                                        
                    score = board_eval_ex_v1(board, moves, row, column, mark, config)    
                    evals += 1
                else:                                        
                    board[column + (row * columns)] = mark #play
                    (score, _, temp_evals) = negamax(board, 3 - mark, depth - 1, -beta, -alpha, moves + 1)                                                              
                    board[column + (row *  columns)] = 0 #undo play                    
                    evals += temp_evals
                    score = score * -1
                if score > best_score:
                    best_score = score
                    best_column = column                     
                alpha = max(alpha, score)
                if alpha >= beta:                                        
                    break #return beta or best score   
        return (alpha, best_column, evals) #Fail-Hard
    
    main_start_time = time()
    
    best_column = None
    best_score = None
    if made_moves == 0: #first move
        best_column = columns//2 #first move to the middle
    elif size - made_moves < 20: #end game
        best_score, best_column, temp_evals = negamax(obs.board[:], obs.mark, size - made_moves, -size, size, made_moves)                 
    else:
        best_score, best_column, total_evals = negamax(obs.board[:], obs.mark, max_depth, -size, size, made_moves)                    
        if abs(best_score)<1:
            # find random move
            scores = random_board_eval(obs.board[:], obs.mark, 100) #about 1sec 150    
            best_score =  float('-inf')             
            for column in range(columns):
                if obs.board[column] == 0 and scores[column] > best_score:
                    best_column, best_score = (column, scores[column])            
    
    debug_out['moves_made'] = made_moves
    debug_out['evals'] = total_evals
    debug_out['best_score'] = best_score
    debug_out['best_column'] = best_column    
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])    
    return best_column

#with random move revaluation ----
#def negamax_agent_hybrid(obs, config):    
#    debug_out = dict()
def negamax_agent_mtd(obs, config):        
    from random import choice    
    from time import time    

    position_table = {}
    win_table = {}   
    
    columns = config.columns
    rows = config.rows
    size = rows * columns   
    column_order = [ columns//2 + (1-2*(i%2)) * (i+1)//2 for i in range(columns)]            
    made_moves = sum(1 if cell != 0 else 0 for cell in obs.board)         
    total_time = time()
    
    total_evals = 0        
    
    max_depth = 4  

    if DEBUG:    
        obs.debug = {}    
        obs.debug['max_depth'] = max_depth    
    
    def board_eval_ex_v3(board, moves, row, column, mark, config):        
        def board_eval_internal(board, moves, row, column, mark, config):        
            inarow = config.inarow - 1  
            inv_mark = 3 - mark        
        
            def count(offset_row, offset_column):
                for i in range(1, inarow + 1):
                    r = row + offset_row * i
                    c = column + offset_column * i
                    if (r < 0 or r >= rows or c < 0 or c >= columns or board[c + (r * columns)] == inv_mark):
                        return i - 1
                return inarow
            score = 0
            score += max(0, 1 + count( 1,  0) + count(-1,  0) - inarow)           
            score += max(0, 1 + count( 0,  1) + count( 0, -1) - inarow)           
            score += max(0, 1 + count(-1, -1) + count( 1,  1) - inarow)           
            score += max(0, 1 + count(-1,  1) + count( 1, -1) - inarow)           
            return score
    
        inv_mark = 3 - mark       
        score = 0

        for index in range(size):
            r = index // columns
            c = index %  columns
            if board[index] == mark:                
                score += board_eval_internal(board, moves, r, c, mark, config)       
            elif board[index] == inv_mark:
                score -= board_eval_internal(board, moves, r, c, inv_mark, config)                
        
        return 0.01*score  
    
    def is_win(board, row, column, mark, config):        
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
    
    def get_move_row(board, column, config):        
        columns = config.columns
        rows = config.rows
        for r in range(rows-1, 0, -1):
            if board[column + (r * columns)] == 0:
                return r
        return 0     

    #alpha = minimum score that the maximizing player is assured of
    #beta the maximum score that the minimizing player is assured of
    def negamax(board, mark, depth, alpha, beta, moves):                         
        board_keys = [0] * columns 
        rows_cache = [0] * columns
        
        evals = 0
        # Tie Game
        if moves == size:
            return (0, None, evals)   
        
        # Can win next.
        for column in column_order:
            if board[column] == 0:
                row = get_move_row(board, column, config)
                rows_cache[column]  = row
                index = column + (row * columns)                
                board[index] = mark
                board_key = hash(tuple(board)) 
                board[index] = 0                         
                if board_key in win_table:
                    is_win_res = win_table[board_key]
                else:
                    is_win_res = is_win(board, row, column, mark, config)                    
                    win_table[board_key] = is_win_res         
                if is_win_res:
                    return ((size + 1 - moves) // 2, column, evals)
                board_keys[column] = board_key                
                #rows_cache[column] = row            
            
        max_score = (size - 1 - moves) // 2	# upper bound of our score as we cannot win immediately
        if beta > max_score:
            beta = max_score                    # there is no need to keep beta above our max possible score.
            if alpha >= beta:                
                return (beta, None, evals)  # prune the exploration if the [alpha;beta] window is empty.                           

        # Recursively check all columns.        
        best_score = -size               
        best_column = None        
        for column in column_order: 
            if board[column] == 0:
                row  = rows_cache[column]                            
                index = column + (row * columns)
                if depth <= 0:                                        
                    board[index] = mark
                    board_key = board_keys[column]  
                    if board_key in position_table:
                        score = position_table[board_key]
                    else:
                        score = board_eval_ex_v3(board, moves, row, column, mark, config) 
                        position_table[board_key] = score                        
                    board[index] = 0
                else:                                        
                    board[index] = mark #play
                    (score, _, temp_evals) = negamax(board, 3 - mark, depth - 1, -beta, -alpha, moves + 1)                                                              
                    board[index] = 0 #undo play                    
                    evals += temp_evals
                    score = score * -1
                if score > best_score:
                    best_score = score
                    best_column = column                     
                alpha = max(alpha, score)      
                if alpha >= beta:                                        
                    break #return beta or best score                                                   
        return (alpha, best_column, evals) #Fail-Hard  
    
    def MTDF(best_score_guess, board, mark, my_depth, made_moves):
        best_score_it = best_score_guess
        best_column_it = None
        upper_bound = size
        lower_bound = -size        
        
        mtd_it = 0      
        mtdf_evals = 0
             
        while lower_bound < upper_bound:                         
            mtd_it += 1            
            #beta = max(best_score_it, lower_bound + 1)
            beta = best_score_it + 1 if best_score_it == lower_bound else best_score_it            
            best_score_it, best_column_it, temp_evals = negamax(board[:], mark, my_depth, beta - 1, beta, made_moves) 
            #print('%d depth %d score %s, col %s, evals %s, alpha %s,beta %s, upper %s lower %s' % (mtd_it, my_depth, best_score_it, best_column_it, temp_evals, beta - 1, beta, upper_bound, lower_bound ))
            mtdf_evals = mtdf_evals  + temp_evals            
            if best_score_it < beta:
                upper_bound = best_score_it
            else:
                lower_bound = best_score_it
        return best_score_it, best_column_it, mtdf_evals, mtd_it             
    
    main_start_time = time()
    
    best_column = None
    best_score = -size
    if made_moves == 0: #first move
        best_column = columns//2 #first move to the middle    
    else:
        depth_start_time = time()
         
        time_limit = 7.0 #seconds
        my_depth = max_depth  
         
        if DEBUG:  
            obs.debug['start_depth'] = max_depth
            obs.debug['depth_log'] = dict()        

        best_score_guess = 0                 
          
        while True:                     
            run_time_1 = time() 
            best_score, best_column, mtdf_evals, mtd_it = MTDF(best_score_guess, obs.board[:], obs.mark, my_depth, made_moves)
            total_evals = total_evals  + mtdf_evals                     
            run_time_2 = time()                   
            if DEBUG:  
                obs.debug['depth_log'][my_depth] = (run_time_2 - depth_start_time, run_time_2 - run_time_1, best_score, best_column, mtdf_evals, mtd_it)                                      
            if my_depth >= size - made_moves or abs(best_score)>=1:
                break
            if time() - depth_start_time + 4*(run_time_2 - run_time_1) > time_limit: # check if we have enought time
                break
            my_depth = my_depth + 1 # increment depth      
    
    if DEBUG:  
        obs.debug['moves_made'] = made_moves
        obs.debug['evals'] = total_evals
        obs.debug['best_score'] = best_score
        obs.debug['best_column'] = best_column    
        obs.debug['total_time'] = time()  - total_time
     
    if best_column == None:        
        best_column = choice([c for c in range(columns) if obs.board[c] == 0])    
    return best_column

#random position evaluation 
def random_pos_eval(board, mark, config, n_rounds = 100):
    def get_move_row(board, column, config):        
        columns = config.columns
        rows = config.rows
        for r in range(rows-1, 0, -1):
            if board[column + (r * columns)] == 0:
                return r
        return 0 
    def is_win(board, row, column, mark, config):
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
    def play_random_game(board, mark, config):        
        columns = config.columns        
        for column in range(columns):
            if board[column] == 0:
                row = get_move_row(board, column, config)                
                if is_win(board, row, column, mark, config):
                    return mark
        #choose the random position if we can win 
        possible_moves = [c for c in range(columns) if board[c] == 0]
        if len(possible_moves) == 0:
            return 0 # tie
        column = choice(possible_moves)
        row = get_move_row(board, column, config)                
        board[column + (row * columns)] = mark        
        return play_random_game(board,  3 - mark , config)              
        
   
    columns = config.columns
    ratings = dict()
    for column in range(columns):
        if board[column] == 0:
            row = get_move_row(board, column, config)                
            if is_win(board, row, column, mark, config):
                ratings[column] = 1
            else:
                board[column + (row * columns)] = mark #play
                outcome = [play_random_game(board[:],3 - mark, config) for  i in range(n_rounds)] 
                outcome = [1 if o == mark else ( 0 if o == 0 else -1) for o in outcome ]
                board[column + (row *  columns)] = 0 #undo play    
                print('%d %f' % (column, sum(outcome)/len(outcome)))
                ratings[column] = sum(outcome)/len(outcome)
    return ratings 

def random_agent_ex(obs, config):    
    from random import choice  
    from time import time      
    
    def get_move_row(board, column, config):        
        columns = config.columns
        rows = config.rows
        for r in range(rows-1, 0, -1):
            if board[column + (r * columns)] == 0:
                return r
        return 0 
    def is_win(board, row, column, mark, config):
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
    def play_random_game(board, mark, config):        
        columns = config.columns        

        #check if we can win
        for column in range(columns):
            if board[column] == 0:
                row = get_move_row(board, column, config)                
                if is_win(board, row, column, mark, config):
                    return mark
        #choose the random position if we can't win 
        possible_moves = [c for c in range(columns) if board[c] == 0]
        if len(possible_moves) == 0:
            return 0 # tie
        column = choice(possible_moves)
        row = get_move_row(board, column, config)                
        board[column + (row * columns)] = mark        
        return play_random_game(board, 3 - mark, config)  

    def random_board_eval(board, mark, n_rounds = 100):        
        columns = config.columns
        rows = config.rows
        size = rows * columns   
        
        my_board = board[:]     
        scores = [0] * columns
        
        for column in range(columns):
            if my_board[column] == 0:
                row = get_move_row(my_board, column, config)                
                if is_win(my_board, row, column, mark, config):
                    scores[column] = float('Inf')
                    break                    
                else:
                    my_board[column + (row * columns)] = mark #play
                    outcome = [play_random_game(my_board[:], 3 - mark, config) for  i in range(n_rounds)] 
                    outcome = [1 if m == mark else ( 0 if m == 0 else -1) for m in outcome ]
                    my_board[column + (row *  columns)] = 0 #undo play                        
                    scores[column] = sum(outcome)
        return scores           
        
    columns = config.columns
    rows = config.rows
    size = rows * columns  
    
    main_start_time = time()        

    agg_scores = [0]*columns    
    while True:       
        scores = random_board_eval(obs.board[:], obs.mark, 64) #about 1sec 150        
        for i in range(columns):
            agg_scores[i] = agg_scores[i] + scores[i]     
        if time() - main_start_time > 2.0: #0.86  
            break    
    best_score = float('-inf')
    best_column = 0
    for column in range(columns):
        if obs.board[column] == 0 and agg_scores[column] > best_score:
            best_column, best_score = (column, agg_scores[column])
            
    #print('random agent (%f sec) best col: %s %s' % (time() - main_start_time,  best_column, agg_scores) )                                    
    return best_column
#get_win_percentages(random_agent_ex, 'negamax', 100)
    
# This agent random chooses a non-empty column.
#configuration = {'timeout': 5, 'columns': 7, 'rows': 6, 'inarow': 4, 'steps': 1000}
#observation = {'board': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'mark': 1}
def random_agent(observation, configuration):    
    from random import choice
    return choice([c for c in range(configuration.columns) if observation.board[c] == 0])

#get_win_percentages(random_agent, 'random', 10)

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

#%% Debug Game 
plays_folder = 'D:/Github/KaggleSandbox/connect_x/games/'
play_filename = '5982532.json' #slow game
play_filename = '5984148.json' #lost game
play_filename = '6059058.json' #
play_filename = '6060038.json' #long game
play_filename = '6366313.json' #lost game
play_filename = '6522402.json' #lost game
play_filename = '6632936.json'
play_filename = '6676798.json'
play_filename = '7251262.json'

with open(plays_folder + play_filename, 'r') as outfile:
    game_log = json.load(outfile)

[s[0]['observation']['remainingOverageTime'] for s in game_log['steps']]
[s[0]['observation']['mark'] for s in game_log['steps']]

step_id = 0
board = game_log['steps'][step_id][0]['observation']['board']
mark =  game_log['steps'][step_id][0]['observation']['mark']
print_board(board)

debug_out = dict()
negamax_agent_mtd(structify({'board':board, 'mark':mark}) , config, debug_out)
print(debug_out)

for i, s in enumerate(game_log['steps']):    
    print('remainingOverageTime %s' % s[0]['observation']['remainingOverageTime'])

#debug_out = dict()
#negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)
#print(debug_out)

for i, s in enumerate(game_log['steps']):    
    board = s[0]['observation']['board']
    if len([c for c in range(columns) if board[c] == 0])==0:
        break;
    mark =  1 + i % 2
    debug_out = dict()
    negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out)
    #negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out)
    print('%d column: %d, evals: %d, score: %f, depth: %d, time: %f sec' % (i+1, debug_out['best_column'], debug_out['evals'], 0 if debug_out['best_score'] is None else debug_out['best_score'], max(debug_out['depth_log'].keys()) if 'depth_log' in debug_out else 0, debug_out['depth_log'][max(debug_out['depth_log'].keys())][0] if 'depth_log' in debug_out else 0))

move_index = 18-1# can win in 13 moves?
board = game_log['steps'][move_index][0]['observation']['board']
debug_out = dict()
mark = 1 + move_index % 2
negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out)
negamax_agent_mtd(structify({'board':board, 'mark':mark}) , config, debug_out)

negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)
random_agent_ex(structify({'board':board, 'mark':mark}) , config)
negamax_agent_hybrid(structify({'board':board, 'mark':mark}) , config, debug_out)


print_board(board)
random_pos_eval(board, mark, config, 400)

#4.4 s ± 44.5 ms per loop, depth 14
%timeit negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out) 
%timeit random_agent_ex(structify({'board':board, 'mark':mark}) , config)  #1000 rounds - 2.6 sec
    
    
#%% Debug Negamax
    
mark = 1

moves = '44444343331156666656' #445264
moves = '44444343331156666651' #445264
moves = '743454445455236' #445264, next move shoudl be 6
moves = '4444'
        
debug_out = dict()
board = columns * rows * [0]
mark = play_moves(moves, board, config)    
obs = structify({'board':board, 'mark':mark})
negamax_agent_ex(obs , config)
obs.debug

negamax_agent_mtd(structify({'board':board, 'mark':mark}) , config, debug_out)
negamax_agent_hybrid(structify({'board':board, 'mark':mark}) , config, debug_out)
random_agent(structify({'board':board, 'mark':mark}) , config)
random_agent_ex(structify({'board':board, 'mark':mark}) , config)

negamax_agent_mtd(structify({'board':board, 'mark':mark}) , config, debug_out)
print(debug_out)

negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)

negamax_agent_ex(structify({'board':board, 'mark':mark}) , config)
negamax_agent(structify({'board':board, 'mark':mark}) , config, 8)
negamax_agent(structify({'board':board, 'mark':mark}) , config, 13)

#3.79 s ± 595 ms
%timeit negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out)
cProfile.run("negamax_agent(structify({'board':board, 'mark':mark}) , config, debug_out) ")

%timeit negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out)
cProfile.run("negamax_agent_ex(structify({'board':board, 'mark':mark}) , config, debug_out) ")

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
        (score, _) = negamax(next_board, 3 - mark, 10, -size, size)
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
        my_action = negamax_agent_ex(structify(observation), env.configuration, debug_out)    
        observation, reward, done, info = trainer.step(my_action)    
        if 'depth_log' in debug_out:
            res = debug_out['depth_log']
            min_d = min(res.keys())
            max_d = max(res.keys())
            prev_depth = max_d - 1 if max_d > min_d else max_d
                                 
            result.append((run_id, test_agent, debug_out['moves_made'],debug_out['max_depth'], min_d, max_d,len(res), res[max_d][0], res[max_d][1],res[prev_depth][1], res[max_d][4],  time() - start_time, debug_out['best_score'], debug_out['best_column'], debug_out['evals']  ))     
        else:
            result.append((run_id, test_agent, debug_out['moves_made'],debug_out['max_depth'], None,None, None, None,None,None,None, time() - start_time, debug_out['best_score'],debug_out['best_column'], debug_out['evals'] ))     
    return result
    
import pandas as pd
timing_results = list()
for i in range(100):       
    print(i)
    timing_results.extend(get_timing(i))
    #timing_results.extend(get_timing(i, "random"))    

res = pd.DataFrame(timing_results, columns = ['run_id', 'test_agent', 'moves','init_depth', 'min_depth', 'max_depth', 'depth_it', 'cum_depth_time', 'depth_time_cur', 'depth_time_prev', 'depth_evals', 'elapsed', 'best_score', 'best_column', 'evals'])
res.to_csv(os.path.join(DATA_FOLDER, 'timing.csv'))      

#res.plot('move', 'elapsed')
  

#%% Evaluate
def mean_reward(rewards):
    return 100*sum(r[0] for r in rewards) /len(rewards)

def get_win_percentages(agent1, agent2, n_rounds=100):
    # Use default Connect Four setup
    config = {'rows': 6, 'columns': 7, 'inarow': 4}
    # Agent 1 goes first (roughly) half the time         
    outcomes = evaluate("connectx", [agent1, agent2], config, [], n_rounds//2)
    # Agent 2 goes first (roughly) half the time      
    outcomes += [[b,a] for [a,b] in evaluate("connectx", [agent2, agent1], config, [], n_rounds-n_rounds//2)]
    print("Agent 1 Win Percentage:", np.round(outcomes.count([1,-1])/len(outcomes), 2))
    print("Agent 2 Win Percentage:", np.round(outcomes.count([-1,1])/len(outcomes), 2))
    print("Number of Invalid Plays by Agent 1:", outcomes.count([None, 0]))
    print("Number of Invalid Plays by Agent 2:", outcomes.count([0, None]))

#agent_mtd      = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_MTD_v2.py"))
#agent_negamax  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_it_v2_ex.py")) # best scoring
agent_negamax  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_it_v2_ex.py")) # best scoring
agent_negamax_v2  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_NEG_v2.py"))
agent_negamax_v7  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_NEG_v7b.py")) 
agent_negamax_v8  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_NEG_v8.py")) 
#agent_negamax_hyb  = utils.get_last_callable(utils.read_file(DATA_FOLDER + "submission_HYB_v3.py")) 
#get_win_percentages(agent_mtd, 'random', 1)
#get_win_percentages(agent_mtd, 'random', 1)

get_win_percentages('random', 'random', 10)

#get_win_percentages(agent_negamax_hyb, 'random', 10)
#get_win_percentages(agent_negamax_hyb, 'negamax', 100)

get_win_percentages(agent_negamax_v8, 'random', 10)
get_win_percentages(agent_negamax_v8, 'negamax', 10)
get_win_percentages(agent_negamax_v8, agent_negamax_v7, 10)
get_win_percentages(agent_negamax_v7, agent_negamax_v8, 10)

get_win_percentages(agent_negamax_v9, 'random', 10)
get_win_percentages(agent_negamax_v9, 'negamax', 10)
get_win_percentages(agent_negamax_v9, agent_negamax, 10)

get_win_percentages(agent_mtd, 'negamax', 10)
get_win_percentages(agent_negamax, 'negamax', 10)
get_win_percentages(agent_negamax,agent_mtd, 10)


#sanity check 
get_win_percentages(random_agent, 'random', 10)
get_win_percentages(random_agent_ex, 'random', 10)

get_win_percentages(random_agent, 'negamax', 10)
get_win_percentages(random_agent_ex, 'negamax', 10)

get_win_percentages(negamax_agent_ex, 'random', 1)

get_win_percentages(negamax_agent_hybrid, 'random', 10)
get_win_percentages(negamax_agent_hybrid, 'negamax', 10)


get_win_percentages('random', 'random', 10)

get_win_percentages('random', 'random_agent_ex', 10)

get_win_percentages('random_agent', 'random', 10)

print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [random_agent_ex, "random"], num_episodes=10)))
print("My Agent vs Random Agent:", mean_reward(evaluate("connectx", [random_agent_ex, "negamax"], num_episodes=10)))
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
import inspect
import os

def write_agent_to_file(function, file):
    with open(file, "a" if os.path.exists(file) else "w") as f:
        f.write(inspect.getsource(function))
        print(function, "written to", file)

write_agent_to_file(negamax_agent, DATA_FOLDER + "submission_it_v6.py")
write_agent_to_file(negamax_agent_ex, DATA_FOLDER + "submission_it_v5_ex.py")
write_agent_to_file(random_agent, DATA_FOLDER + "submission_R_v1.py")
write_agent_to_file(random_agent_ex, DATA_FOLDER + "submission_R_v2_ex.py")

write_agent_to_file(negamax_agent_hybrid, DATA_FOLDER + "submission_HYB_v3.py")
write_agent_to_file(negamax_agent_mtd, DATA_FOLDER + "submission_MTD_v2_ex.py")

write_agent_to_file(negamax_agent_ex, DATA_FOLDER + "submission_NEG_v9_ex.py")
write_agent_to_file(negamax_agent_ex, DATA_FOLDER + "submission_NEG_v7b.py")

write_agent_to_file(negamax_agent_ex, DATA_FOLDER + "submission_NEG_v8a.py")



#%% Validate

import sys
out = sys.stdout
#submission = utils.read_file(DATA_FOLDER + "submission_7.py")
#submission = utils.read_file(DATA_FOLDER + "submission_it_v5_ex.py")
#submission = utils.read_file(DATA_FOLDER + "submission_R_v2_ex.py")
#submission = utils.read_file(DATA_FOLDER + "submission_H_v2_ex.py")
#submission = utils.read_file(DATA_FOLDER + "submission_it_plus.py")
#submission = utils.read_file(DATA_FOLDER + "submission_MTD_v2.py")
#submission = utils.read_file(DATA_FOLDER + "submission_NEG_v7d.py")
submission = utils.read_file(DATA_FOLDER + "submission_NEG_v8b.py")
#submission = utils.read_file(DATA_FOLDER + "submission_HYB_v3.py")
agent = utils.get_last_callable(submission)
sys.stdout = out

env = make("connectx", debug=True)
env.run([agent, agent])
print("Success!" if env.state[0].status == env.state[1].status == "DONE" else "Failed...")
    
#%% test cases
#Test Set (1000 test cases each)	Test Set name	nb moves	nb remaining moves
#Test_L3_R1	End-Easy	28 < moves	remaining < 14
#Test_L2_R1	Middle-Easy	14 < moves <= 28	remaining < 14
#Test_L2_R2	Middle-Medium	14 < moves <= 28	14 <= remaining < 28
#Test_L1_R1	Begin-Easy	moves <= 14	remaining < 14
#Test_L1_R2	Begin-Medium	moves <= 14	14 <= remaining < 28
#Test_L1_R3	Begin-Hard	moves <= 14	28 <= remaining

TEST_CASES_FOLDER = 'D:/Github/KaggleSandbox/connect_x/positions'
    
def read_tests(filename):
    with open(filename, "r") as f:
        lines = f.readlines()
    return [(t.split()[0], int(t.split()[1])) for t in lines]

tests1 = read_tests(TEST_CASES_FOLDER + '/Test_L3_R1') # Total evals 1112549. Total errors 0
tests2 = read_tests(TEST_CASES_FOLDER + '/Test_L2_R1') # Total evals 13329371, Total errors 66
tests3 = read_tests(TEST_CASES_FOLDER + '/Test_L2_R2')    
tests4 = read_tests(TEST_CASES_FOLDER + '/Test_L1_R1')  

def run_tests(tests, filename):
    total_evals = 0
    error_count = 0  
    with open(TEST_CASES_FOLDER + '/' + filename + '.eval.log', "w") as out_file:
        out_file.write('id,moves,score,evals,est_score,est_column,error,time, time_ratio\n')
        for i, t in enumerate(tests):
            #i, t = 0, tests_hard[0]
            mark = 1
            moves =t[0]        
            debug_out = dict()
            board = columns * rows * [0]
            mark = play_moves(moves, board, config)    
            obs = structify({'board':board, 'mark':mark})
            negamax_agent_ex(obs, config)
            #negamax_agent_mtd(obs, config)
            obs.debug['best_score'] = float('nan') if obs.debug['best_score'] is None else obs.debug['best_score']
            text = '%d, test: %s, evals: %s, solver: %f, column: %s  %s %f sec' % (i, t[1], obs.debug['evals'], obs.debug['best_score'], obs.debug['best_column'], '' if abs(t[1] - obs.debug['best_score'])<1e-6 else '[ERROR]', obs.debug['total_time'])
            print(text)
            out_file.write('%d,%s,%s,%s,%f,%s,%s,%f\n' % (i,t[0], t[1], obs.debug['evals'], obs.debug['best_score'], obs.debug['best_column'], 0 if abs(t[1] - obs.debug['best_score'])<1e-6 else 1, obs.debug['total_time']))
            total_evals += obs.debug['evals']
            error_count += 0 if abs(t[1] - obs.debug['best_score'])<1e-6 else 1
        print('Total evals %d' % total_evals)
        print('Total errors %d' % error_count)

for test_name in ['Test_L3_R1', 'Test_L2_R1', 'Test_L2_R2', 'Test_L1_R1', 'Test_L1_R2', 'Test_L1_R3']:
    test_cases = read_tests(TEST_CASES_FOLDER + '/' + test_name)
    run_tests(test_cases, test_name + '.v8')
    

run_tests(tests1, 'test1')
run_tests(tests2, 'test2')
run_tests(tests4, 'test4')

#run solved cases - there should be no errors
tests_solved = read_tests(TEST_CASES_FOLDER + '/Test_SOLVED')
run_tests(tests_solved, 'Test_SOLVED')

tests_hard = read_tests(TEST_CASES_FOLDER + '/Test_L2_R1_HARD')
run_tests(tests_hard, 'Test_L2_R1_HARD.MTD')

agent_negamax_v7(structify({'board':board, 'mark':mark}), config)
