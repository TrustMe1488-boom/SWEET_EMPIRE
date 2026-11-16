"""Event simulation: finite FIFO, production, manual batch delivery, impatience.
Snapshots use only past events; targets count all admitted orders, not sales.
Sessions are independent units of the split; no overlapping window crosses splits.
"""
from common import *
import argparse
def generate(seed=20261114,sessions=240,write=True):
 rng=np.random.default_rng(seed);rows=[]
 for sid in range(sessions):
  chapter=int(rng.integers(1,4));n=int(rng.integers(1,3)) if chapter==1 else int(rng.integers(2,4)) if chapter==2 else 4
  available=np.array([int(i<n) for i in range(4)]);rating=float(rng.uniform(1,5));has_rush=bool(chapter==3 and rng.random()<.6);rush_start=int(rng.integers(250,650))
  duration=900
  horizon=duration+120
  events=[];potential=[];missed=[];pending=[];queue=[];stock=np.zeros(4);station=np.zeros(4);elapsed=np.zeros(4);remaining=8.;service=0.;delivery=0.;delivery_period=float(rng.uniform(8,28));snapshots=[]
  for now in range(horizon+1):
   rush=has_rush and rush_start<=now<rush_start+90
   elapsed+=available*(station<5)
   for i in range(n):
    if elapsed[i]>=CONFIG['base_times'][i] and station[i]<5:
     station[i]+=1;elapsed[i]=0
   if now>=delivery:
    room=5
    for i in rng.permutation(n):
     amount=min(room,station[i],([8,6,5,3] if chapter==1 else [12,9,7,5] if chapter==2 else [16,12,10,7])[i]-stock[i]);stock[i]+=amount;station[i]-=amount;room-=int(amount)
    delivery=now+delivery_period
   queue=[q for q in queue if now-q[0]<CONFIG['types'][q[2]]['patience']*(1.2 if rush else 1)]
   if queue and stock[queue[0][1]]>0:
    service+=1
    if service>=2: stock[queue[0][1]]-=1;queue.pop(0);service=0
   else: service=0
   remaining-=1
   if remaining<=0:
    kind=rng.choice(TYPES,p=[CONFIG['types'][t]['share'] for t in TYPES])
    eligible=[1,1,1,1] if rng.random()<TRAFFIC['independent_wish_share'] else available
    product=int(rng.choice(4,p=probabilities(eligible,kind,rush)))
    potential.append((now,product,kind))
    pending.append((now+TRAFFIC['approach_seconds'],now+TRAFFIC['decision_seconds'],product,kind,False))
    remaining=float(rng.uniform(3,4) if rush else rng.uniform(8,10)/np.clip(1+.1*(rating-4),.7,1.1))
   keep=[]
   for arrival,decision,product,kind,noted in pending:
    if not noted and now>=decision:
     noted=True
     if not available[product]:missed.append((now,product,kind))
    if now>=arrival:
     if available[product] and len(queue)<5:
      event=(now,product,kind);events.append(event);queue.append(event)
    else:keep.append((arrival,decision,product,kind,noted))
   pending=keep
   if now<=duration and now%30==0:
    snapshots.append((now,features(now,events,rating,chapter,available,rush,potential,missed)))
  split='train' if sid%10<6 else 'validation' if sid%10<8 else 'test'
  for now,x in snapshots:
   y=[sum(now<e[0]<=now+120 and e[1]==i for e in events) for i in range(4)]
   rows.append(dict(session=sid,split=split,**dict(zip(FEATURES,x)),**dict(zip(TARGETS,y))))
 df=pd.DataFrame(rows)
 if not write: return df
 df.to_csv(OUT/'dataset.csv',index=False)
 (OUT/'dataset_metadata.json').write_text(json.dumps({'seed':seed,'sessions':sessions,'rows':len(df),'target':'created admitted orders in (t,t+120], served and abandoned','synthetic':True,'demand_process':'pedestrian-v1','split':'session ID modulo 10; 60/20/20','limitations':'fixed assortment/rating per session; idealized manual delivery; Rush has exact 90-second duration; no tutorial'},indent=2))
 return df
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--sessions',type=int,default=240);args=parser.parse_args();df=generate(sessions=args.sessions);print('Generated',len(df),'causal windows')
