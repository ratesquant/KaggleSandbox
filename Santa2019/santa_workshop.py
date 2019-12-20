#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Dec  8 23:44:52 2019

@author: chirokov
"""

import numpy as np
import pandas as pd
import os
import matplotlib.pyplot as plt


DATA_FOLDER = '/home/chirokov/source/github/KaggleSandbox/Santa2019/data' 

#for dirname, _, filenames in os.walk(DATA_FOLDER):
#    for filename in filenames:
#        print(os.path.join(dirname, filename))
        
data = pd.read_csv(os.path.join(DATA_FOLDER, 'family_data.csv'), index_col='family_id')
submission = pd.read_csv(os.path.join(DATA_FOLDER,'ex3/solution.csv'), index_col='family_id')

family_size_dict = data[['n_people']].to_dict()['n_people']

cols = [f'choice_{i}' for i in range(10)]
choice_dict = data[cols].to_dict()
choice_map = data[cols].transpose().to_dict()
choice_list = [{choice_map[i]['choice_%d'%j]:j for j in range(10)} for i in range(5000)]
ordered_choices = [[choice_map[i]['choice_%d'%j] for j in range(10)] for i in range(5000)]

penalty_map = [( 0,   0),
           ( 50,  0),
           ( 50,  9),
           (100,  9),
           (200,  9),
           (200, 18),
           (300, 18),
           (300, 36),
           (400, 36),
           (500, 36 + 199),
           (500, 36 + 398)]

N_DAYS = 100
MAX_OCCUPANCY = 300
MIN_OCCUPANCY = 125

# from 100 to 1
days = list(range(N_DAYS,0,-1))

#%% Objective function

#curr_solution = submission['assigned_day'].tolist()
#cost_function(curr_solution) - cost_function_orig(curr_solution)
#%timeit cost_function(curr_solution) 
#%timeit cost_function_orig(curr_solution) 

def daily_count(prediction):
    daily_occupancy = np.zeros(N_DAYS)
    for f, d in enumerate(prediction):
        daily_occupancy[d-1] += family_size_dict[f]
    return daily_occupancy

def daily_accounting_cost(daily_occupancy):    
    daily_occupancy = np.minimum(MAX_OCCUPANCY, np.maximum(MIN_OCCUPANCY, daily_occupancy))    
    daily_cost = ((daily_occupancy-125.0) / 400.0) * np.power(daily_occupancy, (0.5 + np.abs(np.diff(daily_occupancy, append = daily_occupancy[-1])) / 50.0))    
    return daily_cost
        
    
def cost_function(prediction, choice_mult = 1.0, acct_mult = 1.0, constr_mult = 1.0 ):
    choice_penalty = 0
    daily_occupancy = np.zeros(N_DAYS)        
    for f, d in enumerate(prediction):        
        n = family_size_dict[f]                
        daily_occupancy[d-1] += n        
        choices = choice_list[f]
        pc, pn = penalty_map[choices[d]] if d in choices else penalty_map[-1]
        choice_penalty += pc + pn * n
    
    constr_penalty = np.sum( (daily_occupancy > MAX_OCCUPANCY) | (daily_occupancy < MIN_OCCUPANCY))
    
    daily_occupancy = np.minimum(MAX_OCCUPANCY, np.maximum(MIN_OCCUPANCY, daily_occupancy))    
    accounting_cost = np.sum(((daily_occupancy-125.0) / 400.0) * np.power(daily_occupancy, (0.5 + np.abs(np.diff(daily_occupancy, append = daily_occupancy[-1])) / 50.0)))       

    return choice_mult * choice_penalty + acct_mult * accounting_cost + constr_mult * constr_penalty

def cost_function_orig(prediction):

    penalty = 0

    # We'll use this to count the number of people scheduled each day
    daily_occupancy = {k:0 for k in days}
    
    # Looping over each family; d is the day for each family f
    for f, d in enumerate(prediction):

        # Using our lookup dictionaries to make simpler variable names
        n = family_size_dict[f]
        choice_0 = choice_dict['choice_0'][f]
        choice_1 = choice_dict['choice_1'][f]
        choice_2 = choice_dict['choice_2'][f]
        choice_3 = choice_dict['choice_3'][f]
        choice_4 = choice_dict['choice_4'][f]
        choice_5 = choice_dict['choice_5'][f]
        choice_6 = choice_dict['choice_6'][f]
        choice_7 = choice_dict['choice_7'][f]
        choice_8 = choice_dict['choice_8'][f]
        choice_9 = choice_dict['choice_9'][f]

        # add the family member count to the daily occupancy
        daily_occupancy[d] += n

        # Calculate the penalty for not getting top preference
        if d == choice_0:
            penalty += 0
        elif d == choice_1:
            penalty += 50
        elif d == choice_2:
            penalty += 50 + 9 * n
        elif d == choice_3:
            penalty += 100 + 9 * n
        elif d == choice_4:
            penalty += 200 + 9 * n
        elif d == choice_5:
            penalty += 200 + 18 * n
        elif d == choice_6:
            penalty += 300 + 18 * n
        elif d == choice_7:
            penalty += 300 + 36 * n
        elif d == choice_8:
            penalty += 400 + 36 * n
        elif d == choice_9:
            penalty += 500 + 36 * n + 199 * n
        else:
            penalty += 500 + 36 * n + 398 * n

    # for each date, check total occupancy
    #  (using soft constraints instead of hard constraints)
    for _, v in daily_occupancy.items():
        if (v > MAX_OCCUPANCY) or (v < MIN_OCCUPANCY):
            penalty += 100000000

    # Calculate the accounting cost
    # The first day (day 100) is treated special
    accounting_cost = (daily_occupancy[days[0]]-125.0) / 400.0 * daily_occupancy[days[0]]**(0.5)
    # using the max function because the soft constraints might allow occupancy to dip below 125
    accounting_cost = max(0, accounting_cost)
    
    # Loop over the rest of the days, keeping track of previous count
    yesterday_count = daily_occupancy[days[0]]
    for day in days[1:]:
        today_count = daily_occupancy[day]
        diff = abs(today_count - yesterday_count)
        accounting_cost += max(0, (daily_occupancy[day]-125.0) / 400.0 * daily_occupancy[day]**(0.5 + diff / 50.0))
        yesterday_count = today_count

    penalty += accounting_cost

    return penalty

#%% Start with the sample submission values
best_solution = submission['assigned_day'].tolist()
start_score = cost_function(best_solution)

new = best_solution.copy()
# loop over each family
for fam_id, _ in enumerate(best):
    # loop over each family choice
    for pick in range(10):
        day = choice_dict[f'choice_{pick}'][fam_id]
        temp = new.copy()
        temp[fam_id] = day # add in the new pick
        if cost_function(temp) < start_score:
            new = temp.copy()
            start_score = cost_function(new)

submission['assigned_day'] = new
score = cost_function(new)
submission.to_csv(f'submission_{score}.csv')
print(f'Score: {score}')

plt.figure(1,figsize=(10,8),dpi=72)
plt.plot(daily_count(best_solution),'.-k')
plt.plot(daily_accounting_cost(daily_count(best_solution)), '.-')
plt.grid()

#%% stocastic optimizer
#best_solution = submission['assigned_day'].tolist()
#best_objective = cost_function(best_solution)

my_cost_function = lambda x: cost_function(x, 0.0, 1, 1000)
runs = 10000
tempr = 1

it_obj = np.zeros(runs)

#current_solution = [l[0] for l in ordered_choices] #start with optimal
#current_solution = best_solution.copy()
best_objective = my_cost_function(best_solution)

for i in range(runs):
    index = int(np.floor(5000*np.random.rand()))
    prev = current_solution[index]
    rday = np.random.choice(ordered_choices[index]) if np.random.rand() > 0.01 else int(1 + np.floor(100*np.random.rand()))
    if rday != prev:        
        current_solution[index] = rday
        new_obj = my_cost_function(current_solution)
        if new_obj < best_objective or np.random.rand() < np.exp(-(new_obj - best_objective)/tempr):
            #print('%d %.1f -> %.1f' % (i, best_objective, new_obj) )
            best_solution = current_solution.copy()
            best_objective = new_obj
        else:
            current_solution[index] = prev
    it_obj[i] = best_objective       
    
plt.plot(it_obj)

my_cost_function(best_solution)
my_cost_function(current_solution)

#submission['assigned_day'] = new
#score = cost_function(new)
#submission.to_csv(f'submission_{score}.csv')
#print(f'Score: {score}')

plt.plot(daily_count(best_solution) )
plt.plot(daily_accounting_cost(daily_count(best_solution)))
plt.grid()

plt.plot(daily_count(current_solution) )

#%% check solution
submission = pd.read_csv(os.path.join(DATA_FOLDER,'ex/solution.csv'), index_col='family_id')
solution = submission['assigned_day'].tolist()

cost_function(solution)
plt.plot(daily_count(solution) )
plt.plot(daily_accounting_cost(daily_count(solution)))
plt.grid()
#%% temp
temp = list(best_solution)
daily_count(temp)
temp[4278] = 31 #100
cost_function(temp)

current_solution = 1+np.random.choice(range(100), 5000)

#%% check all files
for dirname, _, filenames in os.walk(DATA_FOLDER):
   for filename in filenames:
       if filename.endswith('.csv') and 'solution' in filename:
           submission = pd.read_csv(os.path.join(dirname, filename), index_col='family_id')
           obj = cost_function(submission['assigned_day'].tolist())
           print('%s/%s: %f' % (dirname, filename, obj))
