# -*- coding: utf-8 -*-
"""
Created on Sun Feb 21 22:13:08 2021

@author: chirokov
"""
import json
import requests
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
#https://www.kaggleusercontent.com/episodes/19285421.json

res = list_episodes_for_team('magicsany')

submission_list = set([19700145, 19683151, 19683130, 19670498, 19670338, 19631045, 19620547, 19620243, 19587733, 19587710, 19570094, 19569847, 19442278, 19541137, 19426528, 19365059, 19302797, 19413351, 19413332,
                       19426528, 19397619, 19397389, 19365059, 19087403, 18987110])

#episodes = list_episodes_for_submission(19683151)
#[s['id'] for s in episodes['result']['submissions']]
#[e['id'] for e in episodes['result']['episodes']]

EPISODE_FOLDER = 'D:/Github/KaggleSandbox/connect_x/analyzed_games'

for sub in submission_list: 
    time.sleep(10*random.random())
    episodes = list_episodes_for_submission(sub)    
    print('Processing sub %d: %d' % (sub, len(episodes['result']['episodes'])) )
    for episode in episodes['result']['episodes']:
        eid = episode['id']
        episode_url = 'https://www.kaggleusercontent.com/episodes/%s.json' % str(eid)
        
        response = requests.get(episode_url, headers=headers)
        if response.ok:
            episode_json = response.json()
            with open(EPISODE_FOLDER + '/%s-%s.json' % (str(sub), str(eid)),'w') as f: 
                json.dump(episode_json, f)
        else:
            print('Could not download episode %s' % eid)


