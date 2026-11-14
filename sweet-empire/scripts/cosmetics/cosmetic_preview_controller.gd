class_name CosmeticPreviewController
extends Node3D
signal cosmetic_preview_started(id: StringName)
signal cosmetic_preview_ended(id: StringName)
var holder: Node3D
var camera: Camera3D
var model: Node3D
var selected: CosmeticDefinition
func _ready():
 holder=Node3D.new();holder.name="PreviewVisualRoot";add_child(holder)
 var world:=WorldEnvironment.new()
 var env:=Environment.new()
 env.background_mode=Environment.BG_COLOR
 env.background_color=Color("#EEE5EB")
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=BakeryVisuals.CREAM
 env.ambient_light_energy=0.48
 world.environment=env;add_child(world)
 var light:=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-55,-25,0)
 light.light_energy=0.16
 light.shadow_enabled=true
 add_child(light)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;add_child(camera)
 camera.current=true
func show_item(item: CosmeticDefinition):
 end_preview()
 selected=item
 model=item.visual_scene.instantiate()
 if item.category=="MIA_OUTFIT":
  model.role="mia"
  model.clothing=BakeryVisuals.CREAM
 elif item.category=="DESSERT_STYLE":model.style=item.style
 holder.add_child(model)
 match item.category:
  "MIA_OUTFIT":
   CosmeticVisualApplicator.apply_outfit(model,item)
   model.rotation.y=-0.35
   camera.position=Vector3(0,1.45,-5)
   camera.look_at(Vector3(0,0.95,0))
  "INTERIOR_THEME":
   CosmeticVisualApplicator.apply_theme(model,item)
   _remove_physics(model)
   camera.position=Vector3(12,13.4,12)
   camera.look_at(Vector3(0,0.6,0))
  "DESSERT_STYLE":
   camera.position=Vector3(5,6,-6)
   camera.look_at(Vector3(0,0.35,0))
 camera.size=item.preview_camera_size
 cosmetic_preview_started.emit(item.id)
func end_preview():
 if selected!=null:cosmetic_preview_ended.emit(selected.id)
 for child in holder.get_children():holder.remove_child(child);child.queue_free()
 model=null
 selected=null
func _remove_physics(node: Node):
 for child in node.get_children():
  if child.name=="CollisionRoot":node.remove_child(child);child.queue_free()
  else:_remove_physics(child)
func _process(delta: float):
 if model!=null and selected!=null:model.rotation.y+=delta*selected.preview_rotation_speed
