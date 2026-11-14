"""Original deterministic procedural café score and effects; no sampled music."""
from pathlib import Path
import math,wave,array,random
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'assets/audio';OUT.mkdir(exist_ok=True,parents=True)
RATE=22050
def save(name,samples):
 peak=max(1,max(abs(v) for v in samples));pcm=array.array('h',(int(max(-1,min(1,v/peak)) * 26000) for v in samples))
 with wave.open(str(OUT/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
def note(buf,start,duration,midi,volume=.12,bright=False):
 frequency=440*2**((midi-69)/12)
 for i in range(min(int(duration*RATE),len(buf)-int(start*RATE))):
  t=i/RATE;env=min(1,t/.018)*math.exp(-t/(.3 if bright else .7))*min(1,(duration-t)/.08)
  value=math.sin(2*math.pi*frequency*t)+.22*math.sin(4*math.pi*frequency*t)
  buf[int(start*RATE)+i]+=value*volume*max(0,env)
def music(name,bpm,shift):
 beat=60/bpm;bars=16;length=bars*4*beat;buf=[0.0]*int(length*RATE)
 chords=[[48,55,60,64],[53,57,60,65],[45,52,57,60],[43,50,55,59]]
 for bar in range(bars):
  chord=chords[(bar//2+shift)%4]
  for step in range(8):
   start=(bar*4+step/2)*beat
   note(buf,start,beat*.85,chord[step%4]+12,.09,True)
   if step%2==0:note(buf,start,beat*1.7,chord[(bar+step//2)%4]+24,.06)
  note(buf,bar*4*beat,beat*3.8,chord[0]-.0,.09)
 # Edge fade prevents clicks in the looping buffer.
 for i in range(min(1000,len(buf)//2)):buf[i]*=i/1000;buf[-1-i]*=i/1000
 save(name,buf)
def effects():
 for index,name in enumerate(['step','equipment','done','pickup','delivery','sale','upgrade','hire','ui','crystal','quest','rush_start','warning','celebrate']):
  duration=2.4 if name=='celebrate' else .7 if name in ['quest','rush_start'] else .15 if name=='step' else .3
  buf=[0.0]*int(duration*RATE)
  notes=[60,64,67,72] if name=='celebrate' else [48+index*2,55+index*2]
  for j,midi in enumerate(notes):note(buf,j*duration/len(notes),duration/len(notes),midi,.18,True)
  save(name,buf)
 rng=random.Random(55);buf=[0.0]*int(12*RATE);last=0.
 for i in range(len(buf)):
  last=.97*last+.03*rng.uniform(-1,1);buf[i]=last*.04
 for second in [1,4,8,10]:note(buf,second,.18,92,.02,True);note(buf,second+.23,.12,96,.012,True)
 save('street',buf)
if __name__=='__main__':
 music('menu',88,0);music('game',96,1);music('rush',138,2);effects();print('18 original PCM WAV assets generated')
