from common import *
from sklearn.linear_model import Ridge
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestRegressor
import pickle,argparse
if __name__=='__main__':
 parser=argparse.ArgumentParser();parser.add_argument('--dataset',type=Path,default=OUT/'dataset.csv');args=parser.parse_args()
 df=pd.read_csv(args.dataset);train=df[df.split=='train'];val=df[df.split=='validation']
 x=train[FEATURES].to_numpy();y=train[TARGETS].to_numpy();vx=val[FEATURES].to_numpy();vy=val[TARGETS].to_numpy()
 scaler=StandardScaler().fit(x);experiments={};candidates={}
 for alpha in [.1,1,10,100,1000]:
  name='Ridge_'+str(alpha);model=Ridge(alpha=alpha).fit(scaler.transform(x),y);candidates[name]=model
  experiments[name]=metrics(vy,masked(model.predict(scaler.transform(vx)),vx))
 forest=RandomForestRegressor(n_estimators=60,max_depth=9,min_samples_leaf=15,random_state=20261114,n_jobs=1).fit(x,y)
 experiments['RandomForest']=metrics(vy,masked(forest.predict(vx),vx))
 # Deployment is a compact reproducible linear model; forest is a measured comparison.
 selected=min(candidates,key=lambda k:experiments[k]['mean_MAE']);model=candidates[selected]
 with (OUT/'trained.pkl').open('wb') as f: pickle.dump((model,scaler),f)
 (OUT/'experiments.json').write_text(json.dumps({'dataset':str(args.dataset.resolve().relative_to(ROOT)),'synthetic':args.dataset.resolve()==(OUT/'dataset.csv').resolve(),'selection':selected,'criterion':'validation MAE among exportable linear candidates; forest comparison reported','validation':experiments},indent=2))
 print(json.dumps({'selected':selected,'validation':experiments},indent=2))
