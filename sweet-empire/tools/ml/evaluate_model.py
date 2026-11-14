from common import *
import pickle
if __name__=='__main__':
 experiments=json.loads((OUT/'experiments.json').read_text())
 df=pd.read_csv(ROOT/experiments['dataset']);test=df[df.split=='test'];train=df[df.split=='train'];x=test[FEATURES].to_numpy();y=test[TARGETS].to_numpy()
 with (OUT/'trained.pkl').open('rb') as f: model,scaler=pickle.load(f)
 average=[]
 for _,row in test.iterrows():
  mask=np.asarray([row['available_'+p] for p in IDS]);matches=train[(train[['available_'+p for p in IDS]].to_numpy()==mask).all(axis=1)&(train.rush==row.rush)]
  average.append(matches[TARGETS].mean().fillna(0).to_numpy() if len(matches) else np.zeros(4))
 recent=masked(x[:,7:11],x)
 report={'ML':metrics(y,masked(model.predict(scaler.transform(x)),x)), 'baseline_mean_assortment':metrics(y,np.array(average)), 'baseline_recent120':metrics(y,recent),'test_sessions':int(test.session.nunique()),'test_rows':len(test),'synthetic_only':experiments['synthetic']}
 (OUT/'metrics.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
