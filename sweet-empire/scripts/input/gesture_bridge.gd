class_name GestureBridge
extends Node
signal packet(data:Dictionary)
signal status_changed(text:String)
var socket:=PacketPeerUDP.new()
var pid:int=-1
var token:String=""
var last_sequence:int=-1
var last_received:int=0
var peer_port:int=0
var status:String="Камера выключена"
var active:bool=false
var camera_ready:bool=false
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS
func start(python:String="python",camera:int=0,synthetic:bool=false)->bool:
 stop()
 if socket.bind(0,"127.0.0.1")!=OK:status="Не удалось открыть локальный IPC";return false
 token=Crypto.new().generate_random_bytes(16).hex_encode();last_sequence=-1;peer_port=0
 pid=OS.create_process(python,PackedStringArray([ProjectSettings.globalize_path("res://Tools/Gestures/fake_sender.py" if synthetic else "res://Tools/Gestures/hand_worker.py"),"--port",str(socket.get_local_port()),"--token",token,"--camera",str(camera)]),false)
 if pid<=0:socket.close();status="Python не найден. Клавиатура доступна.";status_changed.emit(status);return false
 active=true;last_received=Time.get_ticks_msec();status="Запуск камеры…";status_changed.emit(status);return true
func accept(data:Dictionary)->bool:
 if data.get("v")!=1 or data.get("token")!=token:return false
 if not data.get("tracked") is bool:return false
 for key in ["seq","sent_ms"]:
  var value=data.get(key)
  if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)):return false
 var sequence=int(data.get("seq",-1))
 if sequence<=last_sequence:return false
 var age:float=Time.get_unix_time_from_system()*1000-float(data.get("sent_ms",0))
 if age>350 or age< -1000:return false
 if data.get("kind","") not in ["none","palm","pointer","pinch","fist"]:return false
 for key in ["palm","cursor"]:
  if not data.get(key) is Array or data[key].size()!=2:return false
  for value in data[key]:
   if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0 or float(value)>1:return false
 last_sequence=sequence;last_received=Time.get_ticks_msec()
 camera_ready=bool(data.get("camera_ready",false))
 status=str(data.get("status",""));status_changed.emit(status);packet.emit(data);return true
func _process(_delta:float):
 if not active:return
 var budget:int=32
 while socket.get_available_packet_count()>0 and budget>0:
  budget-=1
  var bytes:PackedByteArray=socket.get_packet()
  if socket.get_packet_ip()!="127.0.0.1" or bytes.size()>2048:continue
  var parser:=JSON.new()
  if parser.parse(bytes.get_string_from_utf8())!=OK or not parser.data is Dictionary:continue
  if accept(parser.data):peer_port=socket.get_packet_port()
 if Time.get_ticks_msec()-last_received>350:
  packet.emit({"tracked":false,"kind":"none","palm":[0.5,0.5],"cursor":[0.5,0.5]});last_received=Time.get_ticks_msec()
 if pid>0 and not OS.is_process_running(pid):
  active=false;socket.close();status="Камера недоступна · клавиатура работает";status_changed.emit(status)
func stop():
 if active and peer_port>0:
  socket.set_dest_address("127.0.0.1",peer_port);socket.put_packet(JSON.stringify({"token":token,"quit":true}).to_utf8_buffer())
 if pid>0 and OS.is_process_running(pid):
  var session:Node=get_node_or_null("/root/GameSession")
  if session!=null:session.retire_process(pid)
  else:OS.kill(pid)
 pid=-1;active=false;socket.close();status="Камера выключена"
 packet.emit({"tracked":false,"kind":"none","palm":[0.5,0.5],"cursor":[0.5,0.5]})
func _exit_tree():stop()
