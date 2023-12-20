# -*- coding: utf-8 -*-
"""
Created on Mon Dec 18 20:40:18 2023

@author: chirokov
"""
import numpy as np

#id,puzzle_type,solution_state,initial_state,num_wildcards
#0,cube_2/2/2,A;A;A;A;B;B;B;B;C;C;C;C;D;D;D;D;E;E;E;E;F;F;F;F,D;E;D;A;E;B;A;B;C;A;C;A;D;C;D;F;F;F;E;E;B;F;B;C,0

solution_state = ['A','A','A','A','B','B','B','B','C','C','C','C','D','D','D','D','E','E','E','E','F','F','F','F']
initial_state = ['D','E','D','A','E','B','A','B','C','A','C','A','D','C','D','F','F','F','E','E','B','F','B','C']

moves = {'f0': [0, 1, 19, 17, 6, 4, 7, 5, 2, 9, 3, 11, 12, 13, 14, 15, 16, 20, 18, 21, 10, 8, 22, 23], 'f1': [18, 16, 2, 3, 4, 5, 6, 7, 8, 0, 10, 1, 13, 15, 12, 14, 22, 17, 23, 19, 20, 21, 11, 9], 'r0': [0, 5, 2, 7, 4, 21, 6, 23, 10, 8, 11, 9, 3, 13, 1, 15, 16, 17, 18, 19, 20, 14, 22, 12], 'r1': [4, 1, 6, 3, 20, 5, 22, 7, 8, 9, 10, 11, 12, 2, 14, 0, 17, 19, 16, 18, 15, 21, 13, 23], 'd0': [0, 1, 2, 3, 4, 5, 18, 19, 8, 9, 6, 7, 12, 13, 10, 11, 16, 17, 14, 15, 22, 20, 23, 21], 'd1': [1, 3, 0, 2, 16, 17, 6, 7, 4, 5, 10, 11, 8, 9, 14, 15, 12, 13, 18, 19, 20, 21, 22, 23]}

my_moves = ['r1', '-f1']
for m in my_moves:
    print(m)
    
    ''.join( [initial_state[i] for i in moves['r1']] )

step1 = [initial_state[i] for i in moves['r1']]
step2 = [step1[i] for i in np.argsort(moves['f1'])]

inverse_perm = np.argsort(moves['f1'])

''.join(solution_state)
''.join(initial_state)
''.join(step1)
''.join(step2)

solution= pd.read_csv('D:/Github/KaggleSandbox/Santa2023/data/sample_submission.csv')
puzzle_info = pd.read_csv('D:/Github/KaggleSandbox/Santa2023/data/puzzle_info.csv', index_col='puzzle_type')

allowed_moves = literal_eval(puzzle_info.loc['cube_2/2/2', 'allowed_moves'])
allowed_moves = {k: Permutation(v) for k, v in allowed_moves.items()}

moves = "r1.-f1".split('.')
state = initial_state
for m in moves:
    power = 1
    if m[0] == "-":
        m = m[1:]
        power = -1
    try:
        p = allowed_moves[m]
    except KeyError:
        raise ParticipantVisibleError(f"{m} is not an allowed move for {puzzle_id}.")
    state = (p ** power)(state)
    

total_num_moves = 0
for sol, sub in zip(solution.itertuples(), submission.itertuples()):
    puzzle_id = getattr(sol, series_id_column_name)
    assert puzzle_id == getattr(sub, series_id_column_name)
    allowed_moves = literal_eval(puzzle_info.loc[sol.puzzle_type, 'allowed_moves'])
    allowed_moves = {k: Permutation(v) for k, v in allowed_moves.items()}
    puzzle = Puzzle(
        puzzle_id=puzzle_id,
        allowed_moves=allowed_moves,
        solution_state=sol.solution_state.split(';'),
        initial_state=sol.initial_state.split(';'),
        num_wildcards=sol.num_wildcards,
    )
    total_num_moves += score_puzzle(puzzle_id, puzzle, getattr(sub, moves_column_name))
    
#%% Evaluation metric
import pandas as pd
from ast import literal_eval
from dataclasses import dataclass
from sympy.combinatorics import Permutation
from typing import Dict, List

class ParticipantVisibleError(Exception):
    pass

def score(
        solution: pd.DataFrame,
        submission: pd.DataFrame,
        series_id_column_name: str,
        moves_column_name: str,
        puzzle_info_path: str,
) -> float:
    if list(submission.columns) != [series_id_column_name, moves_column_name]:
        raise ParticipantVisibleError(
            f"Submission must have columns {series_id_column_name} and {moves_column_name}."
        )

    puzzle_info = pd.read_csv(puzzle_info_path, index_col='puzzle_type')
    total_num_moves = 0
    for sol, sub in zip(solution.itertuples(), submission.itertuples()):
        puzzle_id = getattr(sol, series_id_column_name)
        assert puzzle_id == getattr(sub, series_id_column_name)
        allowed_moves = literal_eval(puzzle_info.loc[sol.puzzle_type, 'allowed_moves'])
        allowed_moves = {k: Permutation(v) for k, v in allowed_moves.items()}
        puzzle = Puzzle(
            puzzle_id=puzzle_id,
            allowed_moves=allowed_moves,
            solution_state=sol.solution_state.split(';'),
            initial_state=sol.initial_state.split(';'),
            num_wildcards=sol.num_wildcards,
        )
        total_num_moves += score_puzzle(puzzle_id, puzzle, getattr(sub, moves_column_name))

    return total_num_moves


@dataclass
class Puzzle:
    """A permutation puzzle."""

    puzzle_id: str
    allowed_moves: Dict[str, List[int]]
    solution_state: List[str]
    initial_state: List[str]
    num_wildcards: int


def score_puzzle(puzzle_id, puzzle, sub_solution):
    """Score the solution to a permutation puzzle."""
    # Apply submitted sequence of moves to the initial state, from left to right
    moves = sub_solution.split('.')
    state = puzzle.initial_state
    for m in moves:
        power = 1
        if m[0] == "-":
            m = m[1:]
            power = -1
        try:
            p = puzzle.allowed_moves[m]
        except KeyError:
            raise ParticipantVisibleError(f"{m} is not an allowed move for {puzzle_id}.")
        state = (p ** power)(state)

    # Check that submitted moves solve puzzle
    num_wrong_facelets = sum(not(s == t) for s, t in zip(puzzle.solution_state, state))
    if num_wrong_facelets > puzzle.num_wildcards:
        raise ParticipantVisibleError(f"Submitted moves do not solve {puzzle_id}.")

    # The score for this instance is the total number of moves needed to solve the puzzle
    return len(moves)