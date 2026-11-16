from common import *
import unittest,pickle,tempfile
from build_real_dataset import convert
from generate_dataset import generate
class PipelineTests(unittest.TestCase):
 def test_causal_features(self):
  past=[(10,0,'NORMAL'),(40,1,'IMPATIENT')];a=features(50,past,4,2,[1,1,0,0],False)
  self.assertEqual(a,features(50,past+[(51,2,'SWEET_TOOTH'),(170,3,'NORMAL')],4,2,[1,1,0,0],False))
  self.assertEqual(a[7:11],[1,1,0,0])
  self.assertAlmostEqual(features(5,[(4,0,'NORMAL')],4,1,[1,0,0,0],False)[12],1/30)
 def test_seed_generation(self):
  a=generate(sessions=12,write=False);b=generate(sessions=12,write=False)
  pd.testing.assert_frame_equal(a,b)
  self.assertTrue((a[TARGETS].to_numpy()>=0).all())
 def test_session_splits(self):
  df=pd.read_csv(OUT/'dataset.csv');sets=[set(df[df.split==k].session) for k in ['train','validation','test']]
  self.assertTrue(all(sets));self.assertFalse(sets[0]&sets[1] or sets[0]&sets[2] or sets[1]&sets[2])
  self.assertEqual(len(df),7440)
 def test_targets_availability(self):
  df=pd.read_csv(OUT/'dataset.csv')
  for p in IDS: self.assertTrue((df.loc[df['available_'+p]==0,'next120_'+p]==0).all())
 def test_export_is_trained_model(self):
  data=json.loads((ROOT/'assets/ai/demand_model.json').read_text())
  with (OUT/'trained.pkl').open('rb') as f: model,scaler=pickle.load(f)
  self.assertTrue(np.allclose(data['coefficients'],model.coef_));self.assertEqual(data['features'],FEATURES)
  for vector in json.loads((ROOT/'assets/ai/parity_vectors.json').read_text()):
   x=np.array([vector['features']]);self.assertTrue(np.allclose(masked(model.predict(scaler.transform(x)),x)[0],vector['prediction'],atol=1e-9))
 def test_quality(self):
  report=json.loads((OUT/'metrics.json').read_text())
  self.assertLess(report['ML']['mean_MAE'],report['baseline_mean_assortment']['mean_MAE'])
  self.assertLess(report['ML']['mean_MAE'],report['baseline_recent120']['mean_MAE'])
 def test_real_csv_conversion(self):
  self.assertTrue(OUT.resolve().is_relative_to(ROOT.resolve()))
  with tempfile.TemporaryDirectory(dir=OUT) as temp:
   paths=[]
   for sid in range(10):
    path=Path(temp)/f'session-{sid}.csv'
    pd.DataFrame([dict(time=t,event='OrderCreated',customer_id=t,customer_type='NORMAL',product='COOKIE',rating=4,chapter=1,available='["COOKIE"]',rush=False) for t in range(0,301,30)]).to_csv(path,index=False)
    paths.append(path)
   data=convert(paths)
   self.assertEqual(set(data.split),{'train','validation','test'})
   self.assertTrue((data.next120_COOKIE==4).all())
   self.assertTrue((data.next120_CAKE==0).all())
 def test_probabilities(self):
  for t in TYPES:
   for rush in [False,True]:
    w=probabilities([1,0,1,0],t,rush);self.assertAlmostEqual(w.sum(),1);self.assertEqual(w[1],0);self.assertEqual(w[3],0)
if __name__=='__main__':unittest.main(testRunner=unittest.TextTestRunner(verbosity=2,stream=sys.stdout))
