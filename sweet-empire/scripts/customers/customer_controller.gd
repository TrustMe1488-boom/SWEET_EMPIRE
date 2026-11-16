class_name CustomerController
extends Node3D
signal abandoned(customer)
signal departed(customer)
enum State { Spawn, WalkToQueue, Waiting, Serving, Leave, Despawn }
var state: State = State.Spawn
var customer_type: String = "NORMAL"
var base_patience: float = 20.0
var patience: float = 20.0
var street_exit:bool=false
var street_leg:int=0
var purchased: bool = false
var customer_id: int = 0
var patience_protected: bool = false
var patience_limit: float = 20.0
var _order := CustomerOrder.new()
var _order_assigned: bool = false
var order: CustomerOrder:
 get: return _order
func assign_order(value: CustomerOrder) -> bool:
 if value == null or _order_assigned or state != State.Spawn: return false
 _order = value
 _order_assigned = true
 return true
var queue: QueueManager
var visual: Node3D
var indicator: Label3D
var age: float = 0.0
var patience_bar: MeshInstance3D
var patience_track: MeshInstance3D
func _ready():
 state = State.WalkToQueue
func _physics_process(delta:float):advance(delta)
func _process(delta: float):
 update_visual(delta)
func advance(delta: float):
 age += delta
 if state == State.Leave:
  var exit:Vector3=Vector3(6.6,0,4.5)
  if street_exit:exit=[Vector3(6,0,4.35),Vector3(8.4,0,4.35),Vector3(8.4,0,12)][mini(street_leg,2)]
  position=position.move_toward(exit,delta*2.5)
  if position.distance_to(exit)<0.05 and street_exit and street_leg<2:street_leg+=1
  elif position.distance_to(exit)<0.05:
   state = State.Despawn
   departed.emit(self)
   queue_free()
  return
 if state == State.Despawn: return
 if state != State.Serving:
  if not patience_protected: patience -= delta
  if patience <= 0 and not patience_protected:
   state = State.Leave
   queue.remove(self)
   abandoned.emit(self)
   return
  var target: Vector3 = queue.slot(self)
  position = position.move_toward(target, delta * 2.2)
  state = State.Waiting if position.distance_to(target) < 0.05 else State.WalkToQueue
 if indicator:
  indicator.text = "∞" if patience_protected else "%d с" % ceili(patience)
  if patience_bar: patience_bar.scale.x = clampf(patience / patience_limit, 0.01, 1.0)
  indicator.modulate = Color('#d76a7c') if patience < 6 else Color('#51415f')
func update_visual(delta: float):
 if not visual is ChibiVisual: return
 var model: ChibiVisual = visual
 match state:
  State.WalkToQueue:
   model.set_state(&"Walk")
   var destination := queue.slot(self)
   var direction := destination - position
   if direction.length_squared() > 0.001: model.rotation.y = lerp_angle(model.rotation.y, atan2(-direction.x, -direction.z), delta * 8)
  State.Leave:
   model.set_state(&"Happy" if purchased else &"Leave")
   var direction := Vector3(6.6, 0, 4.5) - position
   model.rotation.y = lerp_angle(model.rotation.y, atan2(-direction.x, -direction.z), delta * 8)
  _:
   model.set_state(&"QueueIdle")
   model.rotation.y = lerp_angle(model.rotation.y, 0, delta * 5)
 if indicator and state == State.Leave:
  indicator.text = "Спасибо!" if purchased else "До встречи…"
  if patience_bar:
   patience_bar.hide()
   patience_track.hide()
func leave():
 state = State.Leave
 queue.remove(self)

func setup_patience_indicator():
 var badge:=Node3D.new();badge.name="OrderProductIcon";add_child(badge);badge.position=Vector3(0,2.3,0)
 BakeryVisuals.product(badge,Vector3.ZERO,order.product_id)
 var nameplate:=BakeryVisuals.label(self,Vector3(0,2.72,0),ProductCatalog.find(order.product_id).display_name,14)
 nameplate.pixel_size=0.006

 for is_fill in [false, true]:
  var mesh := QuadMesh.new()
  mesh.size = Vector2(0.48, 0.055)
  var bar := MeshInstance3D.new()
  bar.mesh = mesh
  var mat := StandardMaterial3D.new()
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.albedo_color = Color("#b9ddd0") if is_fill else Color("#8a788f")
  mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
  mat.no_depth_test = true
  mat.render_priority = 2 if is_fill else 1
  bar.material_override = mat
  add_child(bar)
  bar.position = Vector3(0, 1.9, 0)
  if is_fill: patience_bar = bar
  else: patience_track = bar
