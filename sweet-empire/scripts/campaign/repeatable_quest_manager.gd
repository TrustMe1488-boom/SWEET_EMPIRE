class_name RepeatableQuestManager
extends RefCounted
signal changed
const TEMPLATES=[{"key":"served","title":"Обслужить 20 покупателей","target":20,"reward":3},{"key":"deliveries","title":"Выполнить 12 доставок","target":12,"reward":3},{"key":"cakes","title":"Продать 10 тортов","target":10,"reward":4},{"key":"streak","title":"15 покупателей без ухода","target":15,"reward":5},{"key":"income","title":"Заработать 1000 продажами","target":1000,"reward":5}]
var records:Array=[]
var next_id:int=1
var _seen:Dictionary={}
var wallet:CrystalWallet
var available:Callable
var enabled:bool=false
var sequence_provider:Callable
var activation_sequence:int=0
var last_sequence:int=0
var paused_check:Callable
func _init(crystals:CrystalWallet,products:Callable):wallet=crystals;available=products
func activate():
 if enabled:return
 enabled=true
 activation_sequence=int(sequence_provider.call()) if sequence_provider.is_valid() else last_sequence
 while records.size()<3:_issue()
 changed.emit()
func _issue():
 var keys:Array=[]
 for row in records:keys.append(row.key)
 for offset in TEMPLATES.size():
  var template:Dictionary=TEMPLATES[(next_id-1+offset)%TEMPLATES.size()]
  if template.key in keys:continue
  if template.key=="cakes" and not available.call().any(func(p):return p.id==&"CAKE"):continue
  var record:Dictionary=template.duplicate();record.id="repeat:%d"%next_id;record.progress=0;record.complete=false;record.started_sequence=int(sequence_provider.call()) if sequence_provider.is_valid() else last_sequence
  records.append(record);next_id+=1;return
func receive(kind:StringName,data:Dictionary):
 if not enabled:return
 var sequence:int=int(data.get("event_sequence",-1))
 if sequence<=activation_sequence or _seen.has(str(sequence)):return
 _seen[str(sequence)]=true
 last_sequence=maxi(last_sequence,sequence)
 if paused_check.is_valid() and paused_check.call():return
 var mutated:bool=false
 for row in records:
  if row.complete or sequence<=int(row.get("started_sequence",0)):continue
  var amount:int=0
  match row.key:
   "served":amount=1 if kind==&"CustomerServed" else 0
   "deliveries":amount=1 if kind==&"ProductDelivered" and int(data.get("amount",0))>0 else 0
   "cakes":amount=1 if kind==&"ProductSold" and StringName(data.get("product",&""))==&"CAKE" else 0
   "income":amount=int(data.get("price",0)) if kind==&"ProductSold" else 0
   "streak":
    if kind==&"CustomerLeft":row.progress=0;mutated=true
    elif kind==&"CustomerServed":amount=1
  if amount>0:row.progress=mini(int(row.target),int(row.progress)+amount);row.complete=row.progress>=row.target;mutated=true
 if mutated:changed.emit()
func claim(id:String)->bool:
 for index in records.size():
  var row:Dictionary=records[index]
  if row.id!=id or not row.complete:continue
  if not wallet.grant_once(row.id,int(row.reward)):return false
  records.remove_at(index);_issue();changed.emit();return true
 return false
func get_save_data()->Dictionary:return {"version":1,"enabled":enabled,"records":records.duplicate(true),"next_id":next_id,"seen":_seen.duplicate(),"activation_sequence":activation_sequence,"last_sequence":last_sequence}
func load_save_data(data:Dictionary)->bool:
 if data.get("version")!=1 or not data.get("records") is Array or data.records.size()>3 or not data.get("seen") is Dictionary:return false
 if not data.get("enabled") is bool:return false
 for field in ["next_id","activation_sequence","last_sequence"]:
  var value=data.get(field,0)
  if not (value is int or value is float) or not is_finite(float(value)) or float(value)<0 or float(value)!=floorf(float(value)):return false
 var ids:Dictionary={}
 for row in data.records:
  if not row is Dictionary or not row.has_all(["id","key","target","reward","progress","complete"]) or ids.has(str(row.id)):return false
  if not row.id is String or not row.key is String or not row.complete is bool:return false
  for field in ["target","reward","progress"]:
   if not (row[field] is int or row[field] is float):return false
   if not is_finite(float(row[field])) or float(row[field])!=floorf(float(row[field])):return false
  var found:bool=false
  for template in TEMPLATES:
   if row.key==template.key and int(row.target)==template.target and int(row.reward)==template.reward:found=true
  if not found or int(row.progress)<0 or int(row.progress)>int(row.target) or bool(row.complete)!=(int(row.progress)==int(row.target)):return false
  ids[str(row.id)]=true
 activation_sequence=int(data.get("activation_sequence",0));last_sequence=int(data.get("last_sequence",activation_sequence))
 records=data.records.duplicate(true);next_id=maxi(1,int(data.get("next_id",1)));enabled=bool(data.get("enabled",false));_seen=data.seen.duplicate();changed.emit();return true
