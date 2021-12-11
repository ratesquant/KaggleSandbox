# -*- coding: utf-8 -*-
"""
Created on Sun Feb 21 22:13:08 2021

@author: chirokov
"""
import json
import requests
import random
import time
import os

import matplotlib.pyplot as plt



headers = {"User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36"}

base_url = "https://www.kaggle.com/requests/EpisodeService/"
get_url = base_url + "GetEpisodeReplay"
list_url = base_url + "ListEpisodes"

def get_episode_replay(episode_id):
    body = {
        "EpisodeId": episode_id
    }

    response = requests.post(get_url, json=body)
    return response.json()


def list_episodes(episode_ids):
    return __list_episodes({
        "Ids": episode_ids
    })


def list_episodes_for_team(team_id):
    return __list_episodes({
        "TeamId": team_id
    })


def list_episodes_for_submission(submission_id):
    return __list_episodes({
        "SubmissionId": submission_id
    })


def __list_episodes(body):
    response = requests.post(list_url, json=body)
    return response.json()

#%% download episodes 
#"id": 4241425,
#"teamName": "magicsany",
#"competitionId": 17592,
#"teamLeaderId": 750313,
#https://www.kaggleusercontent.com/episodes/19285421.json

#18524595 - random moves (dont use for training)
#18821366 - weak solver (not for training)

#list_episodes_for_team("4241425")
#requests.post(list_url, json= {"TeamId": "4241425" }).json()


submission_list = set([19700359, 19700145, 19683151, 19683130, 19670498, 19670338, 19631045, 19620547, 19620243, 19587733, 19587710, 19570094, 19569847, 
                       19442278, 19541137, 19426528, 19365059, 19302797, 19413351, 19413332,
                       19426528, 19397619, 19397389, 19365059, 19087403, 18987110, 19002379, 18987110, 18956190, 19725613, 19725787, 19541833, 19748268, 19797665, 19804069, 19810416,
                       19854447, 20324274, 20324395, 20339122, 20971481, 20987943, 21000842, 19683151, 21005650, 21012137, 21086630, 21086463, 21053536, 21167184,
                       21204127, 21217719, 21232435, 21777260, 21777362, 21798662, 22351903, 22363528, 22367398, 22367452, 22507409, 22507534,
                       24260721, 24260700, 23700983, 23478094, 23478019, 23192759, 23185639, 22836693])

#19749534 - long games
top_agents = set([19656705, 18777551, 19160823, 19298291, 18829008, 19669130, 19550625, 19799937, 18837224, 18829008, 23348111, 23420354, 23563401, 23634169])
submission_list.update(top_agents)

#top players
#submission_list = set([19160823,18777551, 19656705, 19298291, 18829031, 19498976])
#episodes = list_episodes_for_submission(19700359)

EPISODE_FOLDER = 'D:/Github/KaggleSandbox/connect_x/analyzed_games'


for sub in sorted(submission_list): 
    while True:
        time.sleep(10*random.random())    
        episodes = list_episodes_for_submission(sub)
        if 'results' in episodes and 'wasSuccessful' in episodes  and episodes['wasSuccessful'] == True:
            break
        else:
            print('will try again [%s]:  %s' % (sub, episodes.keys()))
        
    saved_count = 0      
    for episode in episodes['result']['episodes']:
        eid = episode['id']
        episode_url = 'https://www.kaggleusercontent.com/episodes/%s.json' % str(eid)
        episode_filename =  EPISODE_FOLDER + '/%s-%s.json' % (str(sub), str(eid))
        
        if not os.path.exists(episode_filename):        
            response = requests.get(episode_url, headers=headers)
            if response.ok:
                episode_json = response.json()
                with open(episode_filename,'w') as f: 
                    json.dump(episode_json, f)                
                saved_count = saved_count + 1
            else:
                print('Could not download episode %s' % eid)
    print('Processed sub %d: %d (new %d)' % (sub, len(episodes['result']['episodes']), saved_count) )


#%% check episodes
from datetime import datetime

recent_submission_list = set([19700359,19700145,19670498,19683151,19683130,19620547,19725613,19570094,19002379,19587733,
                          19426528,19442278,19725787,19670338,19620243,19631045,19569847,19541833,19541137, 19748268, 19797665, 
                          19804069, 19810416, 19854447, 20324274, 20324395, 20339122, 21053536, 21086463, 21086630, 21167184, 21204127, 21217719, 20324274, 21232435, 21777260, 21777362, 21798662])


recent_submission_list.update(submission_list)

#[a for a in recent_submission_list if a not in submission_list]
submission_data = {}

with open('D:/Github/KaggleSandbox/connect_x/my_episodes.csv','w', encoding='utf-8') as f: 
    f.write('submission_id, submission_id2, my_team_id, my_team_name, team_id, team_name, episode_id, stime, etime, is_first, score, score_conf, score2, score_conf2, reward, reward2\n')
    for sub in recent_submission_list: 
        time.sleep(10*random.random())
        episodes = list_episodes_for_submission(sub)        
        submission_data[sub] = episodes
        
        team_id_map = {sub['id']:sub['teamId'] for sub in episodes['result']['submissions']}
        team_name_map =  {team['id']:team['teamName'] for team in episodes['result']['teams']}
        
        #ep = [ep for ep in episodes['result']['episodes'] if ep['id'] == 21053505][0]
        
        for ep in episodes['result']['episodes']:
            create_time = datetime.strptime(ep['createTime'].split('.')[0], '%Y-%m-%dT%H:%M:%S') if isinstance(ep['createTime'], str) else datetime.fromtimestamp(ep['createTime']['seconds'])
            end_time    = datetime.strptime(ep['endTime'].split('.')[0], '%Y-%m-%dT%H:%M:%S')    if isinstance(ep['endTime'], str)    else datetime.fromtimestamp(ep['endTime']['seconds'])
            my_agent_index = 0 if ep["agents"][0]["submissionId"] == sub else 1
            vs_agent_index = 1- my_agent_index
            my_agent = ep["agents"][my_agent_index]
            vs_agent = ep["agents"][vs_agent_index]
            
            vs_team_id = team_id_map[vs_agent['submissionId']]
            vs_team_name = team_name_map[vs_team_id]
            
            my_team_id = team_id_map[my_agent['submissionId']]
            my_team_name = team_name_map[my_team_id]
            
            if vs_agent['reward'] is None and  my_agent['updatedScore'] > my_agent['initialScore'] :
                my_agent['reward'] = 1.0
            
            f.write((','.join(['%s']*16) + '\n' )  % (sub, vs_agent['submissionId'],my_team_id,my_team_name, vs_team_id,vs_team_name, ep['id'], str(create_time), str(end_time), vs_agent_index, my_agent["updatedScore"], my_agent["updatedConfidence"], vs_agent["updatedScore"], vs_agent["updatedConfidence"], my_agent['reward'], vs_agent['reward']))
            #print('%s %s -> %s (%s) %s -> %s (%s) %s' % (my_agent_index,  my_agent['initialScore'], my_agent["updatedScore"], my_agent["updatedConfidence"], vs_agent['initialScore'], vs_agent["updatedScore"], vs_agent["updatedConfidence"], my_agent['reward'] ))
    

with open('D:/Github/KaggleSandbox/connect_x/submission_data.json','w') as f: 
    json.dump(submission_data, f)
    
#%% check subhistory
from datetime import datetime

my_submission = 19749534 #long games
my_submission = 19748268 #latest bound
my_submission = 19725787 #random
my_submission = 19700145 #another bound
my_submission = 19797665 #latest bound v2
my_submission = 19002379 #Best Agent

submission_data = {}

episodes = list_episodes_for_submission(my_submission)        

team_id_map = {sub['id']:sub['teamId'] for sub in episodes['result']['submissions']}
team_name_map =  {team['id']:team['teamName'] for team in episodes['result']['teams']}

reward_dict = {1:'W', -1:'L', 0:'T', None:'NA'}

def none2nan(x):
    return float('nan') if x is None else x

for ep in episodes['result']['episodes']:
    create_time = datetime.strptime(ep['createTime'].split('.')[0], '%Y-%m-%dT%H:%M:%S') if isinstance(ep['createTime'], str) else datetime.fromtimestamp(ep['createTime']['seconds'])
    end_time    = datetime.strptime(ep['endTime'].split('.')[0], '%Y-%m-%dT%H:%M:%S')    if isinstance(ep['endTime'], str)    else datetime.fromtimestamp(ep['endTime']['seconds'])
    my_agent_index = 0 if ep["agents"][0]["submissionId"] == my_submission else 1
    vs_agent_index = 1- my_agent_index
    my_agent = ep["agents"][my_agent_index]
    vs_agent = ep["agents"][vs_agent_index]
    
    vs_team_id = team_id_map[vs_agent['submissionId']]
    vs_team_name = team_name_map[vs_team_id]
    
    print(('%s: %s, move: %s, team: %s [%s %s], score: %.1f, %.1f -> %.1f' )  % (str(end_time), reward_dict[my_agent['reward']],  '1st' if vs_agent_index == 1 else '2nd', vs_team_name,vs_agent['submissionId'], vs_agent['initialScore'],  my_agent["updatedScore"] - none2nan(my_agent["initialScore"]) , none2nan(my_agent["initialScore"]), my_agent["updatedScore"]))
    
my_scores = [ep["agents"][0 if ep["agents"][0]["submissionId"] == my_submission else 1]["updatedScore"] for ep in episodes['result']['episodes']]
plt.plot(my_scores)
plt.grid()