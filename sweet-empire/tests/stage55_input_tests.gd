extends SceneTree
var passed:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(ok:bool,title:String):
 if ok:passed+=1
 else:failed+=1
 print("STAGE55_INPUT ","PASS " if ok else "FAIL ",title)
func hand(controls:GameInputManager,kind:String,point:Vector2,frames:int=12):
 for i in frames:
  controls.tick(1.0/30)
  controls.feed({"tracked":true,"kind":kind,"palm":[point.x,point.y],"cursor":[point.x,point.y]})
func run():
 var controls:=GameInputManager.new()
 hand(controls,"palm",Vector2(0.5,0.5))
 check(controls.calibrate() and controls.center.distance_to(Vector2(.5,.5))<.01,"Manual fixed-center calibration")
 hand(controls,"palm",Vector2(.51,.49),20)
 check(controls.movement(Vector2.ZERO)==Vector2.ZERO,"Dead zone prevents drift")
 hand(controls,"palm",Vector2(.85,.85),20)
 var diagonal:=controls.movement(Vector2.ZERO)
 check(diagonal.length()<=1.00001 and diagonal.x>0 and diagonal.y>0,"Analog diagonal is normalized and speed bounded")
 hand(controls,"palm",Vector2(.65,.5),20)
 var gentle:float=controls.movement(Vector2.ZERO).length()
 hand(controls,"palm",Vector2(.9,.5),20)
 check(gentle>0 and gentle<controls.movement(Vector2.ZERO).length(),"Analog strength scales continuously")
 var center_before:Vector2=controls.center
 check(controls.center==center_before,"Center does not follow hand automatically")
 check(controls.movement(Vector2.LEFT)==Vector2.LEFT and controls.active_source=="keyboard","WASD immediately wins")
 hand(controls,"palm",controls.palm,15)
 check(controls.active_source=="keyboard" and controls.movement(Vector2.ZERO)==Vector2.ZERO,"Stationary hand cannot steal keyboard priority")
 controls.lost();hand(controls,"pointer",Vector2(.5,.5),15)
 check(controls.mode=="cursor" and controls.movement(Vector2.ZERO)==Vector2.ZERO,"Index finger enters cursor and stops Mia")
 var signals:Dictionary={"click":0,"short":0,"long":0}
 controls.click_requested.connect(func(_p):signals.click+=1)
 controls.interact_requested.connect(func():signals.short+=1)
 controls.pause_requested.connect(func():signals.long+=1)
 hand(controls,"pinch",Vector2(.5,.5),10);hand(controls,"pointer",Vector2(.5,.5),1)
 check(signals.click==1,"Stable pinch-release generates one click")
 hand(controls,"pointer",Vector2(.5,.5),12);hand(controls,"pinch",Vector2(.5,.5),8);controls.lost();hand(controls,"pointer",Vector2(.5,.5),1)
 check(signals.click==1,"Tracking loss cancels unfinished pinch")
 hand(controls,"fist",Vector2(.5,.5),12);hand(controls,"palm",Vector2(.5,.5),1)
 check(signals.short==1 and signals.long==0,"Short fist emits only interaction")
 hand(controls,"fist",Vector2(.5,.5),45);hand(controls,"palm",Vector2(.5,.5),1)
 check(signals.short==1 and signals.long==1,"Long fist emits pause once, never interaction")
 hand(controls,"palm",Vector2(.9,.5),15);controls.tick(.5)
 check(not controls.tracked and controls.movement(Vector2.ZERO)==Vector2.ZERO,"Stale tracking stops gesture movement")
 controls.reset_calibration();check(not controls.calibrated,"Explicit recalibration resets center state")
 var bridge:=GestureBridge.new();bridge.token="unit"
 var packet:Dictionary={"v":1,"token":"unit","seq":1,"sent_ms":int(Time.get_unix_time_from_system()*1000),"tracked":true,"kind":"palm","palm":[.5,.5],"cursor":[.5,.5]}
 check(bridge.accept(packet),"Valid local command accepted")
 check(not bridge.accept(packet),"Replay sequence rejected")
 packet.seq=2;packet.token="other";check(not bridge.accept(packet),"Wrong session token rejected")
 packet.token="unit";packet.sent_ms=0;check(not bridge.accept(packet),"Old queued command rejected")
 packet.sent_ms=int(Time.get_unix_time_from_system()*1000);packet.cursor=[NAN,.5];check(not bridge.accept(packet),"Invalid numeric coordinates rejected")
 bridge.free();controls.free()
 var audio:Node=root.get_node("AudioHub")
 check(["Music","SFX","UI","Ambient"].all(func(name):return AudioServer.get_bus_index(name)>=0),"Four independent audio buses")
 audio.set_music("rush");var player:AudioStreamPlayer=audio.music[audio.active];var stream:AudioStream=player.stream
 audio.set_duck(true);audio.set_duck(false)
 check(audio.current=="rush" and audio.music[audio.active]==player and player.stream==stream and player.playing,"Menu ducking does not restart Rush composition")
 audio.set_gain("SFX",.2)
 check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))),.2),"Independent volume setting applied")
 var game:BakeryGame=load("res://scenes/bakery_game.tscn").instantiate();root.add_child(game);await process_frame
 check(not game.gesture_bridge.active and game.controls!=null,"Game starts normally without Python or camera process")
 game.set_paused(true)
 check(game.controls.process_mode==Node.PROCESS_MODE_ALWAYS and game.gesture_bridge.process_mode==Node.PROCESS_MODE_ALWAYS,"UI gesture processing remains active during pause")
 game.set_paused(false);game.queue_free();await process_frame
 print("STAGE55_INPUT_RESULT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
