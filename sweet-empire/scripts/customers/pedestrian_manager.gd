class_name PedestrianManager
extends Node
const MAX_VISIBLE:int=8
const DOOR=Vector3(6.7,0,4.35)
const SIDEWALK=Vector3(8.4,0,4.35)
var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ai/traffic_config.json"))
var game:Node
var visitors:Array[PedestrianController]=[]
var next_id:int=1
var appearance_rng:=RandomNumberGenerator.new()
var counts:Dictionary={"potential":{},"missed":{},"entries":{},"full_queue":0}
func _ready():appearance_rng.seed=41755
func _physics_process(delta:float):advance(delta,true)
func advance(delta:float,run_spawner:bool=false):
 if run_spawner:game.spawner._process(delta)
 for visitor in visitors.duplicate():visitor.advance(delta)
func request_pedestrian():
 if visitors.size()>=MAX_VISIBLE:return
 var tutorial=game.progression.tutorial if game.progression!=null else null
 if tutorial!=null and not tutorial.first_served and (tutorial.first_customer_spawned or not visitors.is_empty()):return
 var type:String=game.utility_ai.choose_type(game.spawner.rng)
 if game._next_customer_id<=3:type="NORMAL"
 var assortment:Array[ProductDefinition]=game.development.orderable_products()
 # Most guests read the menu; a fifth bring an independent wish, including
 # products not yet offered. This keeps early traffic viable and exposes unmet demand.
 var candidates:Array[ProductDefinition]=ProductCatalog.all() if game.spawner.rng.randf()<float(config.independent_wish_share) else assortment
 var desire:CustomerOrder=game.utility_ai.choose(candidates,game.spawner.rng,type,game.spawner.rush_mode)
 if desire==null:return
 if tutorial!=null and not tutorial.first_served:desire=CustomerOrder.new(&"COOKIE");type="NORMAL"
 var data:Dictionary={"id":next_id,"desired":str(desire.product_id),"type":type,"position":Vector3(8.4,0,-15),"route":[SIDEWALK,Vector3(8.4,0,12)],"waypoint":0,"decided":false,"appearance":{"color":[BakeryVisuals.PINK,BakeryVisuals.MINT,BakeryVisuals.LAVENDER,BakeryVisuals.CARAMEL][appearance_rng.randi_range(0,3)],"skin":[Color("#edc1a0"),Color("#d5a383"),Color("#bd886b")][appearance_rng.randi_range(0,2)],"variant":appearance_rng.randi_range(0,3)}}
 next_id+=1
 _create(data)
 _record("PotentialDemand",desire.product_id,next_id-1)
func _create(data:Dictionary)->PedestrianController:
 var visitor:=PedestrianController.new();visitor.flow=self;visitor.visitor_id=int(data.id)
 visitor.desired_product=StringName(data.desired);visitor.customer_type=str(data.type);visitor.position=data.position
 visitor.route.assign(data.route);visitor.waypoint=int(data.waypoint);visitor.decided=bool(data.decided);visitor.appearance=data.appearance.duplicate()
 add_child(visitor);visitors.append(visitor)
 visitor.visual=BakeryVisuals.person(visitor,visitor.appearance.color,false,visitor.appearance.skin,visitor.appearance.variant)
 if visitor.appearance.variant%2==0:
  BakeryVisuals.box(visitor.visual.body,Vector3(0,0.68,0.21),Vector3(0.3,0.3,0.17),BakeryVisuals.LAVENDER)
 return visitor
func _record(kind:String,id:StringName,visitor_id:int):
 var metric:String={"PotentialDemand":"potential","MissedPotentialDemand":"missed","CustomerEntered":"entries"}[kind]
 counts[metric][str(id)]=int(counts[metric].get(str(id),0))+1
 var type:String="NORMAL"
 for visitor in visitors:
  if visitor.visitor_id==visitor_id:type=visitor.customer_type
 game.events.publish(StringName(kind),{"product":str(id),"visitor_id":visitor_id,"customer_type":type},str(visitor_id))
func decide(visitor:PedestrianController):
 var available:bool=game.development.orderable_products().any(func(p):return p.id==visitor.desired_product)
 if not available:
  _record("MissedPotentialDemand",visitor.desired_product,visitor.visitor_id)
  return
 visitor.route=[SIDEWALK,DOOR]
func arrived(visitor:PedestrianController):
 if visitor.route.back()==DOOR:
  var available:bool=game.development.orderable_products().any(func(p):return p.id==visitor.desired_product)
  if available and game.queue.customers.size()<QueueManager.CAPACITY:
   var customer:CustomerController=game.spawn_customer(CustomerOrder.new(visitor.desired_product),visitor.customer_type,visitor.appearance)
   if customer!=null:
    customer.position=DOOR
    customer.street_exit=true
    customer.visual.get_parent().remove_child(customer.visual);customer.visual.queue_free()
    visitor.remove_child(visitor.visual);customer.add_child(visitor.visual);customer.visual=visitor.visual;visitor.visual=null
    _record("CustomerEntered",visitor.desired_product,visitor.visitor_id)
   else:_pass(visitor);return
  else:counts.full_queue+=1;_pass(visitor);return
 visitors.erase(visitor);visitor.queue_free()
func _pass(visitor:PedestrianController):
 visitor.route=[visitor.position,SIDEWALK,Vector3(8.4,0,12)];visitor.waypoint=1
func get_save_data()->Dictionary:
 var people:Array=[]
 for visitor in visitors:people.append(visitor.get_save_data())
 return {"next_id":next_id,"counts":counts.duplicate(true),"visitors":people,"appearance_seed":appearance_rng.seed,"appearance_state":appearance_rng.state}
func load_save_data(data:Dictionary):
 for visitor in visitors:remove_child(visitor);visitor.queue_free()
 visitors.clear();next_id=int(data.next_id);counts=data.counts.duplicate(true)
 for record in data.visitors:_create(record)
 appearance_rng.seed=int(data.appearance_seed);appearance_rng.state=int(data.appearance_state)
