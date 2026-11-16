"""Local MediaPipe hand worker. Explicit camera start; no network services or frames IPC."""
from pathlib import Path
import argparse,json,socket,sys,time,traceback
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'.local/gesture-python'))
from recognizer import command
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--port',type=int,required=True);parser.add_argument('--token',required=True);parser.add_argument('--camera',type=int,default=0);parser.add_argument('--debug',action='store_true');parser.add_argument('--probe',action='store_true');args=parser.parse_args()
 sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);sock.bind(('127.0.0.1',0));sock.setblocking(False)
 sequence=0;cap=None;detector=None
 def send(data,captured_ms=None):
  nonlocal sequence
  sequence+=1
  data.update(v=1,token=args.token,seq=sequence,sent_ms=int(time.time()*1000) if captured_ms is None else captured_ms)
  sock.sendto(json.dumps(data).encode(),('127.0.0.1',args.port))
 try:
  import cv2,mediapipe as mp
  model=Path(__file__).parent/'models/hand_landmarker.task'
  options=mp.tasks.vision.HandLandmarkerOptions(base_options=mp.tasks.BaseOptions(model_asset_path=str(model)),running_mode=mp.tasks.vision.RunningMode.VIDEO,num_hands=1,min_hand_detection_confidence=.65,min_hand_presence_confidence=.65,min_tracking_confidence=.65)
  detector=mp.tasks.vision.HandLandmarker.create_from_options(options)
  cap=cv2.VideoCapture(args.camera,cv2.CAP_DSHOW)
  cap.set(cv2.CAP_PROP_FRAME_WIDTH,640);cap.set(cv2.CAP_PROP_FRAME_HEIGHT,480);cap.set(cv2.CAP_PROP_BUFFERSIZE,1)
  if not cap.isOpened():raise RuntimeError('Camera unavailable: connect a webcam and check Windows camera permissions')
  start=time.monotonic();last_tick=-1
  while True:
   try:
    data,_=sock.recvfrom(2048)
    request=json.loads(data)
    if request.get('token')==args.token and request.get('quit'):break
   except BlockingIOError:pass
   captured_ms=int(time.time()*1000)
   ok,frame=cap.read()
   if not ok:raise RuntimeError('Camera disconnected or failed to read frame')
   frame=cv2.flip(frame,1)
   timestamp=max(last_tick+1,int((time.monotonic()-start)*1000));last_tick=timestamp
   result=detector.detect_for_video(mp.Image(image_format=mp.ImageFormat.SRGB,data=cv2.cvtColor(frame,cv2.COLOR_BGR2RGB)),timestamp)
   output=command(result.hand_landmarks[0] if result.hand_landmarks else None)
   output.update(camera_ready=True,status='Hand tracked' if output['tracked'] else 'Show an open palm')
   send(output,captured_ms)
   if args.debug:
    cv2.putText(frame,output['kind'],(20,35),cv2.FONT_HERSHEY_SIMPLEX,1,(100,220,180),2);cv2.imshow('SWEET EMPIRE - local camera debug',frame)
    if cv2.waitKey(1)==27:break
   if args.probe and time.monotonic()-start>=5:break
   time.sleep(.005)
 except Exception as error:
  send(dict(tracked=False,camera_ready=False,kind='none',status=str(error),palm=[.5,.5],cursor=[.5,.5]))
  log=ROOT/'.local/gesture-worker.log';log.parent.mkdir(exist_ok=True);log.write_text(traceback.format_exc(),encoding='utf-8')
  print(type(error).__name__+': '+str(error),flush=True)
  return 2
 finally:
  if cap is not None:cap.release()
  if detector is not None:detector.close()
  try:
   import cv2;cv2.destroyAllWindows()
  except ImportError:pass
  sock.close()
 return 0
if __name__=='__main__':raise SystemExit(main())
