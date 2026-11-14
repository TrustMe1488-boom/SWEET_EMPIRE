"""Convert explicit in-game event exports to causal windows. One file = one session.
Requires at least ten separate sessions so all three session splits are present.
CSV snapshots at t need recorded context at/before t and at least 120s of future.
"""
from common import *
import argparse
def convert(paths):
 if len(paths)<10: raise ValueError('Provide >=10 separate session CSV files; never split one session into files')
 rows=[]
 for sid,path in enumerate(paths):
  frame=pd.read_csv(path).sort_values('time',kind='stable')
  orders=frame[frame.event=='OrderCreated']
  potential=[(float(r.time),IDS.index(r.product),str(r.customer_type)) for r in frame[frame.event=="PotentialDemand"].itertuples() if r.product in IDS]
  missed=[(float(r.time),IDS.index(r.product),str(r.customer_type)) for r in frame[frame.event=="MissedPotentialDemand"].itertuples() if r.product in IDS]
  events=[(float(r.time),IDS.index(r.product),str(r.customer_type)) for r in orders.itertuples() if r.product in IDS and r.customer_type in TYPES]
  for now in range(0,int(frame.time.max())-119,30):
   known=frame[frame.time<=now]
   if known.empty:continue
   state=known.iloc[-1];assortment=json.loads(state.available)
   available=[int(p in assortment) for p in IDS];rush=str(state.rush).lower()=='true'
   x=features(now,events,float(state.rating),int(state.chapter),available,rush,potential,missed)
   y=[sum(now<e[0]<=now+120 and e[1]==i for e in events) for i in range(4)]
   rows.append(dict(session=sid,split='train' if sid%10<6 else 'validation' if sid%10<8 else 'test',**dict(zip(FEATURES,x)),**dict(zip(TARGETS,y))))
 return pd.DataFrame(rows)
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('csv',nargs='+');args=parser.parse_args()
 result=convert(args.csv);result.to_csv(OUT/'real_dataset.csv',index=False);print('Real-session windows:',len(result))
