"""Landmark-to-command adapter; no image leaves the Python process."""
from math import hypot
def classify(points):
 if not points or len(points)!=21:return 'none'
 # Wrist-relative distances work with tilted hands; joint extension test avoids
 # depending solely on vertical screen coordinates.
 def extended(tip,pip):
  a,b,w=points[tip],points[pip],points[0]
  return hypot(a.x-w.x,a.y-w.y)>hypot(b.x-w.x,b.y-w.y)*1.17
 index=extended(8,6);middle=extended(12,10);ring=extended(16,14);little=extended(20,18)
 span=max(.025,hypot(points[5].x-points[17].x,points[5].y-points[17].y))
 pinch=hypot(points[4].x-points[8].x,points[4].y-points[8].y)/span
 if pinch<.28 and not ring and not little:return 'pinch'
 if index and not middle and not ring and not little:return 'pointer'
 if index and middle and ring and little:return 'palm'
 if not index and not middle and not ring and not little:return 'fist'
 return 'none'
def command(points):
 if not points:return {'tracked':False,'kind':'none','palm':[.5,.5],'cursor':[.5,.5]}
 palm=[sum(getattr(points[i],axis) for i in [0,5,9,13,17])/5 for axis in ['x','y']]
 cursor=[points[8].x,points[8].y]
 return {'tracked':True,'kind':classify(points),'palm':[max(0,min(1,v)) for v in palm],'cursor':[max(0,min(1,v)) for v in cursor]}
