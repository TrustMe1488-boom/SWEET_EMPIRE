"""Shared causal feature contract. No dependency in the shipped Godot runtime."""
from pathlib import Path
import sys,json
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/ml-python'))
import numpy as np
import pandas as pd
CONFIG=json.loads((ROOT/'assets/ai/customer_profiles.json').read_text())
TRAFFIC=json.loads((ROOT/'assets/ai/traffic_config.json').read_text())
IDS=CONFIG['products']; TYPES=list(CONFIG['types'])
FEATURES=['rating','chapter']+['available_'+p for p in IDS]+['rush']+['orders120_'+p for p in IDS]+['orders30','arrival_rate']+['share_'+t for t in TYPES]+['session_time']+['opportunity_'+p for p in IDS]+['potential120_'+p for p in IDS]+['missed120_'+p for p in IDS]
TARGETS=['next120_'+p for p in IDS]
OUT=ROOT/'Tools/ML/artifacts';OUT.mkdir(exist_ok=True,parents=True)
def probabilities(available,kind,rush):
 w=np.asarray(CONFIG['types'][kind]['weights'],dtype=float)*available
 if rush: w*=1+0.15*4/np.asarray(CONFIG['base_times'])
 return w/w.sum() if w.sum()>0 else np.zeros(4)
def features(now,events,rating,chapter,available,rush,potential=(),missed=()):
 history=[e for e in events if now-120<=e[0]<=now]
 counts=[sum(e[1]==i for e in history) for i in range(4)]
 recent=sum(e[0]>=now-30 for e in history)
 shares=[sum(e[2]==t for e in history)/max(1,len(history)) for t in TYPES]
 interval=3.5 if rush else 9/np.clip(1+.1*(rating-4),.7,1.1)
 opportunity=sum(CONFIG['types'][t]['share']*((1-TRAFFIC['independent_wish_share'])*probabilities(available,t,rush)+TRAFFIC['independent_wish_share']*probabilities([1,1,1,1],t,rush)*available) for t in TYPES)*120/interval
 return [rating,chapter,*available,int(rush),*counts,recent,len(history)/min(120,max(30,now)),*shares,now,*opportunity,*[sum(now-120<=e[0]<=now and e[1]==i for e in potential) for i in range(4)],*[sum(now-120<=e[0]<=now and e[1]==i for e in missed) for i in range(4)]]
def metrics(y,p):
 p=np.maximum(0,p)
 return {'MAE':dict(zip(IDS,np.abs(y-p).mean(axis=0).tolist())),'RMSE':dict(zip(IDS,np.sqrt(((y-p)**2).mean(axis=0)).tolist())), 'mean_MAE':float(np.abs(y-p).mean()),'mean_RMSE':float(np.sqrt(((y-p)**2).mean(axis=0)).mean())}
def masked(pred,x):
 return np.maximum(0,pred)*x[:,2:6]
