class_name GameInputManager
extends Node
signal interact_requested
signal pause_requested
signal click_requested(position:Vector2)
signal cursor_moved(position:Vector2)
var calibrated:bool=false
var center:Vector2=Vector2(0.5,0.5)
var palm:Vector2=Vector2(0.5,0.5)
var cursor:Vector2=Vector2(0.5,0.5)
var sensitivity:float=2.0
var deadzone:float=0.12
var gesture_vector:Vector2=Vector2.ZERO
var active_source:String="keyboard"
var mode:String="movement"
var tracked:bool=false
var clock:float=0
var last_feed:float=-100
var kind:String="none"
var stable_for:float=0
var kind_since:float=0
var fist_start:float=-1
var long_sent:bool=false
var pinch_start:float=-1
var pinch_anchor:Vector2
var blocked_kind:String=""
var keyboard_anchor:Vector2
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS
func tick(delta:float):
 clock+=maxf(0,delta)
 if clock-last_feed>0.35:lost()
func _process(delta:float):tick(delta)
func calibrate()->bool:
 if not tracked:return false
 center=palm;calibrated=true;gesture_vector=Vector2.ZERO;blocked_kind=kind;keyboard_anchor=palm;return true
func reset_calibration():calibrated=false;clear_motion()
func keyboard_action():
 active_source="keyboard";keyboard_anchor=palm;blocked_kind=kind;gesture_vector=Vector2.ZERO;fist_start=-1;pinch_start=-1
func clear_motion():
 gesture_vector=Vector2.ZERO;blocked_kind=kind;keyboard_anchor=palm;fist_start=-1;pinch_start=-1
func lost():
 tracked=false;gesture_vector=Vector2.ZERO;stable_for=0;kind="none";fist_start=-1;pinch_start=-1;long_sent=false;blocked_kind="palm" if active_source=="keyboard" else ""
func movement(keyboard:Vector2)->Vector2:
 if keyboard.length()>0.001:keyboard_action();return keyboard.limit_length(1)
 return gesture_vector if active_source=="gesture" and tracked and calibrated and mode=="movement" else Vector2.ZERO
func feed(data:Dictionary):
 last_feed=clock
 if not bool(data.get("tracked",false)):lost();return
 tracked=true
 var raw:=Vector2(float(data.palm[0]),float(data.palm[1]))
 palm=palm.lerp(raw,0.35)
 var next:String=str(data.kind)
 if next!=kind:stable_for=0;kind_since=clock
 else:stable_for=clock-kind_since
 if kind=="fist" and next!="fist":
  if fist_start>=0 and not long_sent and clock-fist_start>=0.12 and clock-fist_start<0.85:active_source="gesture";interact_requested.emit()
  fist_start=-1;long_sent=false
 if kind=="pinch" and next!="pinch":
  if next=="pointer" and pinch_start>=0 and clock-pinch_start>=0.09 and clock-pinch_start<=0.8 and cursor.distance_to(pinch_anchor)<0.04:click_requested.emit(cursor)
  pinch_start=-1
 kind=next
 if stable_for<0.12:gesture_vector=Vector2.ZERO;return
 if blocked_kind==kind and raw.distance_to(keyboard_anchor)<0.1:gesture_vector=Vector2.ZERO;return
 blocked_kind=""
 if kind=="fist":
  gesture_vector=Vector2.ZERO
  if fist_start<0:fist_start=clock
  if clock-fist_start>=0.85 and not long_sent:long_sent=true;active_source="gesture";pause_requested.emit()
 elif kind in ["pointer","pinch"]:
  active_source="gesture";mode="cursor";gesture_vector=Vector2.ZERO
  cursor=cursor.lerp(Vector2(float(data.cursor[0]),float(data.cursor[1])),0.4);cursor_moved.emit(cursor)
  if kind=="pinch" and pinch_start<0:pinch_start=clock;pinch_anchor=cursor
 elif kind=="palm" and calibrated:
  var offset:Vector2=(palm-center)*sensitivity
  var strength:float=clampf((offset.length()-deadzone)/(0.7-deadzone),0,1)
  if strength>0.02:active_source="gesture"
  mode="movement";gesture_vector=offset.normalized()*strength if strength>0 else Vector2.ZERO
 else:gesture_vector=Vector2.ZERO
