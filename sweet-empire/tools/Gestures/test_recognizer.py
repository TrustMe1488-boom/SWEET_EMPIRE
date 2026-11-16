import unittest
from types import SimpleNamespace as P
from recognizer import classify,command
def points(extended=()):
 p=[P(x=.5,y=.8) for _ in range(21)]
 p[5]=P(x=.35,y=.65);p[17]=P(x=.65,y=.65);p[4]=P(x=.75,y=.7)
 for tip,pip,x in [(8,6,.4),(12,10,.5),(16,14,.6),(20,18,.7)]:p[pip]=P(x=x,y=.5);p[tip]=P(x=x,y=.2 if tip in extended else .78)
 return p
class RecognitionTests(unittest.TestCase):
 def test_open(self):self.assertEqual(classify(points([8,12,16,20])),'palm')
 def test_fist(self):self.assertEqual(classify(points()),'fist')
 def test_pointer(self):self.assertEqual(classify(points([8])),'pointer')
 def test_pinch(self):
  p=points([8]);p[4]=P(x=p[8].x+.01,y=p[8].y+.01);self.assertEqual(classify(p),'pinch')
 def test_missing(self):self.assertFalse(command(None)['tracked'])
 def test_normalized(self):self.assertTrue(all(0<=v<=1 for v in command(points([8,12,16,20]))['palm']))
if __name__=='__main__':
 import sys
 unittest.main(testRunner=unittest.TextTestRunner(verbosity=2,stream=sys.stdout))
