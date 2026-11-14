"""Explicit, bounded local hardware check. Never writes video/images."""
from pathlib import Path
import sys,time,json
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'.local/gesture-python'))
import cv2,mediapipe as mp,numpy as np
result={'mediapipe':mp.__version__,'opencv':cv2.__version__,'model_loaded':False,'camera_opened':False,'frames':0,'tracked_frames':0}
options=mp.tasks.vision.HandLandmarkerOptions(base_options=mp.tasks.BaseOptions(model_asset_path=str(Path(__file__).parent/'models/hand_landmarker.task')),running_mode=mp.tasks.vision.RunningMode.VIDEO,num_hands=1)
with mp.tasks.vision.HandLandmarker.create_from_options(options) as detector:
 result['model_loaded']=True
 blank=mp.Image(image_format=mp.ImageFormat.SRGB,data=np.zeros((480,640,3),dtype=np.uint8))
 start=time.perf_counter();output=detector.detect_for_video(blank,1)
 result['blank_inference_ms']=(time.perf_counter()-start)*1000;result['blank_hands']=len(output.hand_landmarks)
 cap=cv2.VideoCapture(0,cv2.CAP_DSHOW);result['camera_opened']=cap.isOpened();begin=time.monotonic()
 try:
  while cap.isOpened() and time.monotonic()-begin<5:
   ok,frame=cap.read()
   if not ok:break
   timestamp=int((time.monotonic()-begin)*1000)+2
   output=detector.detect_for_video(mp.Image(image_format=mp.ImageFormat.SRGB,data=cv2.cvtColor(cv2.flip(frame,1),cv2.COLOR_BGR2RGB)),timestamp)
   result['frames']+=1;result['tracked_frames']+=bool(output.hand_landmarks)
 finally:cap.release()
result['manual_gesture_accuracy_tested']=False
(ROOT/'Documentation/stage55-camera-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
