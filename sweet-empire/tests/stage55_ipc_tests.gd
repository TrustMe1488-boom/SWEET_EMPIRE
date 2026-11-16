extends SceneTree
var packets:int=0
func _initialize():run.call_deferred()
func run():
 var bridge:=GestureBridge.new();root.add_child(bridge)
 bridge.packet.connect(func(data):
  if data.get("tracked",false):packets+=1)
 var started:bool=bridge.start("python",0,true)
 await create_timer(1.5).timeout
 var pid:int=bridge.pid
 print("STAGE55_IPC started=",started," tracked_packets=",packets)
 var ok:bool=started and packets>10
 bridge.stop();await create_timer(1.2).timeout
 ok=ok and not OS.is_process_running(pid)
 bridge.queue_free();await process_frame
 print("STAGE55_IPC_RESULT ","PASS" if ok else "FAIL");quit(0 if ok else 1)
