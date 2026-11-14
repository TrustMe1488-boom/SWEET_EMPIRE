from common import *
import pickle
if __name__=='__main__':
 with (OUT/'trained.pkl').open('rb') as f: model,scaler=pickle.load(f)
 experiments=json.loads((OUT/'experiments.json').read_text())
 data={'version':1,'schema_version':2,'features':FEATURES,'products':IDS,'horizon_seconds':120,'mean':scaler.mean_.tolist(),'scale':scaler.scale_.tolist(),'coefficients':model.coef_.tolist(),'intercepts':model.intercept_.tolist(),'metadata':{'demand_process':'pedestrian-v1','algorithm':experiments['selection'],'synthetic':experiments['synthetic'],'seed':20261114,'split':'by session, not rows','limitations':'synthetic performance is not real-session accuracy'}}
 (ROOT/'assets/ai/demand_model.json').write_text(json.dumps(data,indent=2))
 df=pd.read_csv(ROOT/experiments['dataset']);x=df[df.split=='test'][FEATURES].iloc[::71].to_numpy()
 y=masked(model.predict(scaler.transform(x)),x)
 (ROOT/'assets/ai/parity_vectors.json').write_text(json.dumps([{'features':a.tolist(),'prediction':b.tolist()} for a,b in zip(x,y)],indent=2))
 print('Exported',len(FEATURES),'features;',len(x),'parity vectors')

 # Cross-language feature fixtures are independent of prediction parity vectors.
 cases=[]
 for now,events,rating,chapter,available,rush in [
  (0,[],4.0,1,[1,0,0,0],False),
  (5,[(4,0,'NORMAL')],4.0,1,[1,0,0,0],False),
  (150,[(29,0,'NORMAL'),(30,0,'NORMAL'),(120,1,'IMPATIENT'),(150,1,'SWEET_TOOTH'),(151,0,'NORMAL')],4.4,2,[1,1,0,0],False),
  (240,[(130,2,'SWEET_TOOTH'),(220,3,'NORMAL')],4.8,3,[1,1,1,1],True)]:
  cases.append(dict(time=now,events=events,rating=rating,chapter=chapter,available=available,rush=rush,features=features(now,events,rating,chapter,available,rush)))
 (ROOT/'assets/ai/feature_vectors.json').write_text(json.dumps(cases,indent=2))
