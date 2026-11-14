extends Node
const BUSES=["Music","SFX","UI","Ambient"]
var music:Array[AudioStreamPlayer]=[]
var pool:Array[AudioStreamPlayer]=[]
var equipment:AudioStreamPlayer
var _step_distance:float=0
var ambient:AudioStreamPlayer
var current:String=""
var active:int=0
var positions:Dictionary={}
var cooldowns:Dictionary={}
var gains:Dictionary={"Music":0.55,"SFX":0.55,"UI":0.5,"Ambient":0.25}
var cache:Dictionary={}
var ducked:bool=false
var fades:Tween
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS
 for bus in BUSES:
  if AudioServer.get_bus_index(bus)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
  set_gain(bus,gains[bus])
 for i in 2:
  var player:=AudioStreamPlayer.new();player.bus="Music";add_child(player);music.append(player)
 for i in 8:
  var player:=AudioStreamPlayer.new();add_child(player);pool.append(player)
 ambient=AudioStreamPlayer.new();ambient.bus="Ambient";ambient.volume_db=-24;add_child(ambient)
 equipment=AudioStreamPlayer.new();equipment.bus="Ambient";equipment.volume_db=-34;equipment.stream=stream("equipment",true);add_child(equipment)
 get_tree().node_added.connect(_hook)
func _hook(node:Node):
 if node is BaseButton and not node.has_meta("audio_hook"):
  node.set_meta("audio_hook",true);node.pressed.connect(func():play_sound("ui",0))
func stream(name:String,loop:bool=false)->AudioStreamWAV:
 var key:=name+str(loop)
 if cache.has(key):return cache[key]
 var resource:AudioStreamWAV=load("res://assets/audio/"+name+".wav")
 var sound:AudioStreamWAV=resource.duplicate()
 if loop:sound.loop_mode=AudioStreamWAV.LOOP_FORWARD;sound.loop_begin=0;sound.loop_end=roundi(sound.get_length()*sound.mix_rate)
 cache[key]=sound;return sound
func set_gain(bus:String,value:float):
 if bus not in BUSES:return
 gains[bus]=clampf(value,0,1)
 var index:=AudioServer.get_bus_index(bus)
 if index>=0:AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,gains[bus]))+(-7 if bus=="Music" and ducked else 0));AudioServer.set_bus_mute(index,gains[bus]<=0)
func set_music(name:String):
 if name==current:return
 if fades!=null and fades.is_valid():fades.kill()
 if not current.is_empty():positions[current]=music[active].get_playback_position()
 var old:int=active;active=1-active;current=name
 var player:AudioStreamPlayer=music[active];player.stream=stream(name,true);player.volume_db=-55;player.play(float(positions.get(name,0)))
 fades=create_tween();fades.set_parallel(true)
 fades.tween_property(player,"volume_db",-12.0,0.8)
 fades.tween_property(music[old],"volume_db",-55.0,0.8)
 fades.chain().tween_callback(music[old].stop)
 if name=="menu":ambient.stop()
 elif not ambient.playing:ambient.stream=stream("street",true);ambient.play()
func set_duck(value:bool):
 if value==ducked:return
 ducked=value
 set_gain("Music",gains.Music)
func play_sound(name:String,priority:int=1):
 if quitting:return
 var now:int=Time.get_ticks_msec();var gap:int=150
 if name in ["warning","celebrate","equipment"]:gap=2000
 if now-int(cooldowns.get(name,-10000))<gap:return
 cooldowns[name]=now
 var chosen:AudioStreamPlayer
 for player in pool:
  if not player.playing:chosen=player;break
 if chosen==null:
  for player in pool:
   if int(player.get_meta("priority",0))<priority:chosen=player;break
 if chosen==null:return
 chosen.set_meta("priority",priority);chosen.bus="UI" if name=="ui" else "SFX";chosen.volume_db=-18 if name=="step" else -13
 chosen.stream=stream(name);chosen.play()
func event(kind:StringName,data:Dictionary):
 var sound:String={&"ProductProduced":"done",&"ProductPickedUp":"pickup",&"ProductDelivered":"delivery",&"ProductSold":"sale",&"StationUpgraded":"upgrade",&"ChefHired":"hire",&"EquipmentPurchased":"upgrade"}.get(kind,"")
 if not sound.is_empty():play_sound(sound)

func footstep(distance:float):
 _step_distance+=distance
 if _step_distance>=0.65:_step_distance=fmod(_step_distance,0.65);play_sound("step")
func _process(_delta:float):
 if quitting:return
 set_duck(get_tree().paused)
 var scene:Node=get_tree().current_scene
 var working:bool=false
 if scene is BakeryGame and not get_tree().paused:
  working=scene.development.stations.values().any(func(station):return station.has_cook and station.inventory.count<5)
 if working and not equipment.playing:equipment.play()
 elif not working:equipment.stop()

func _exit_tree():
 if fades!=null and fades.is_valid():fades.kill()
 for player in music+pool+[ambient,equipment]:
  if is_instance_valid(player):player.stop();player.stream=null
 cache.clear()

var quitting:bool=false
func quit_game():
 if quitting:return
 quitting=true
 _exit_tree()
 await get_tree().create_timer(0.15,true).timeout
 get_tree().quit()
