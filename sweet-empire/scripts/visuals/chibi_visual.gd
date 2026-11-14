class_name ChibiVisual
extends Node3D
@export_enum("mia", "cook", "cashier", "customer", "sophie") var role: String = "customer"
@export var clothing: Color = Color("#b9ddd0")
@export var skin: Color = Color("#edc1a0")
@export_range(0, 3) var variant: int = 0
static var npc_meshes:Dictionary={}
var state: StringName = &"Idle"
var phase: float = 0.0
var interaction_time: float = 0.0
var body: Node3D
var head: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var tray: Node3D
var cookie_root: Node3D
var smile: Node3D
var bag: Node3D
var apron: bool
func pivot(parent: Node3D, title: String, at: Vector3) -> Node3D:
 var node := Node3D.new()
 node.name = title
 parent.add_child(node)
 node.position = at
 return node
func _ready():
 apron = role in ["mia", "cook", "cashier", "sophie"]
 body = pivot(self, "Body", Vector3.ZERO)
 var shirt := BakeryVisuals.cylinder(body, Vector3(0, 0.66, 0), 0.27, 0.49, clothing)
 shirt.scale.z = 0.8
 BakeryVisuals.cylinder(body, Vector3(0, 0.43, 0), 0.29, 0.16, clothing.darkened(0.07))
 for side in [-1, 1]:
  var leg := pivot(body, "LeftLeg" if side < 0 else "RightLeg", Vector3(side * 0.13, 0.37, 0))
  BakeryVisuals.cylinder(leg, Vector3(0, -0.12, 0), 0.085, 0.25, Color("#6f627c"))
  var shoe := BakeryVisuals.ball(leg, Vector3(0, -0.29, -0.035), 0.12, Color("#6a4d52"))
  shoe.scale = Vector3(0.85, 0.65, 1.35)
  if side < 0: left_leg = leg
  else: right_leg = leg
  var arm := pivot(body, "LeftArm" if side < 0 else "RightArm", Vector3(side * 0.31, 0.83, 0))
  BakeryVisuals.ball(arm, Vector3(0, -0.07, 0), 0.125, clothing)
  BakeryVisuals.cylinder(arm, Vector3(0, -0.17, 0), 0.075, 0.2, clothing)
  BakeryVisuals.ball(arm, Vector3(0, -0.29, 0), 0.09, skin)
  if side < 0: left_arm = arm
  else: right_arm = arm
 if apron:
  var apron_color: Color = BakeryVisuals.PINK if role == "mia" else (BakeryVisuals.MINT if role == "cook" else BakeryVisuals.LAVENDER)
  if role == "sophie": apron_color = BakeryVisuals.MINT.darkened(0.05)
  BakeryVisuals.box(body, Vector3(0, 0.7, -0.225), Vector3(0.3, 0.29, 0.035), apron_color)
  BakeryVisuals.box(body, Vector3(0, 0.47, -0.25), Vector3(0.45, 0.24, 0.045), apron_color)
  BakeryVisuals.box(body, Vector3(0, 0.46, -0.28), Vector3(0.18, 0.095, 0.018), apron_color.darkened(0.12))
  if role == "sophie":
   BakeryVisuals.box(body, Vector3(0.1, 0.76, -0.25), Vector3(0.12, 0.065, 0.025), BakeryVisuals.CREAM)
  for side in [-1, 1]:
   BakeryVisuals.box(body, Vector3(side * 0.13, 0.85, -0.19), Vector3(0.04, 0.22, 0.045), apron_color)
   BakeryVisuals.ball(body, Vector3(side * 0.17, 0.58, 0.22), 0.09, apron_color)
 head = pivot(body, "Head", Vector3(0, 1.18, -0.015))
 var hair_colors: Array[Color] = [Color("#79533f"), Color("#493947"), Color("#b5774b"), Color("#d3af78")]
 var hair: Color = hair_colors[variant % 4] if role == "customer" else Color("#784c3b")
 if role == "sophie": hair = Color("#556359")
 BakeryVisuals.ball(head, Vector3(0, 0.03, 0.015), 0.39, hair)
 var face := BakeryVisuals.ball(head, Vector3(0, -0.025, -0.09), 0.35, skin)
 face.scale.z = 0.93
 for side in [-1, 1]:
  BakeryVisuals.ball(head, Vector3(side * 0.34, -0.035, -0.02), 0.075, skin)
  var white := BakeryVisuals.ball(head, Vector3(side * 0.123, 0.0, -0.385), 0.075, Color("#fff8ef"))
  white.scale = Vector3(0.85, 1.08, 0.28)
  var eye := BakeryVisuals.ball(head, Vector3(side * 0.123, -0.003, -0.405), 0.052, Color("#493441"))
  eye.scale = Vector3(0.8, 1, 0.32)
  BakeryVisuals.ball(head, Vector3(side * 0.123 - 0.012, 0.018, -0.423), 0.014, Color.WHITE)
  var blush := BakeryVisuals.ball(head, Vector3(side * 0.23, -0.09, -0.32), 0.063, Color("#e6a2a0"))
  blush.scale = Vector3(1, 0.4, 0.22)
  var brow := BakeryVisuals.box(head, Vector3(side * 0.12, 0.11, -0.35), Vector3(0.09, 0.018, 0.025), hair)
  brow.rotation.z = side * -0.1
 BakeryVisuals.ball(head, Vector3(0, -0.045, -0.415), 0.035, skin.lightened(0.08))
 smile = pivot(head, "Smile", Vector3(0, -0.14, -0.39))
 for side in [-1, 1]:
  var lip := BakeryVisuals.box(smile, Vector3(side * 0.022, 0, 0), Vector3(0.05, 0.018, 0.018), Color("#925e60"))
  lip.rotation.z = side * 0.25
 for i in 4:
  var bang := BakeryVisuals.ball(head, Vector3(-0.23 + i * 0.145, 0.205 + abs(i - 1.5) * 0.025, -0.25), 0.14, hair)
  bang.scale = Vector3(1, 0.85, 0.8)
 if role in ["mia", "sophie"] or (role == "customer" and variant % 2 == 0):
  for side in [-1, 1]:
   var tail := BakeryVisuals.ball(head, Vector3(side * 0.32, -0.03, 0.18), 0.19, hair)
   tail.scale.y = 1.3
   BakeryVisuals.ball(head, Vector3(side * 0.34, 0.06, 0.16), 0.075, BakeryVisuals.PINK if role in ["mia", "sophie"] else clothing)
 if role in ["mia", "cook"]:
  BakeryVisuals.cylinder(head, Vector3(0, 0.38, 0), 0.28, 0.18, BakeryVisuals.CREAM)
  BakeryVisuals.cylinder(head, Vector3(0, 0.33, 0), 0.29, 0.05, Color("#eee2da"))
  for offset in [Vector3(-0.18, 0.51, 0), Vector3(0.17, 0.53, 0), Vector3(0, 0.58, -0.04), Vector3(0, 0.52, 0.15)]:
   BakeryVisuals.ball(head, offset, 0.2, Color("#fff9ed"))
 elif role == "cashier":
  BakeryVisuals.box(head, Vector3(0, 0.29, -0.2), Vector3(0.6, 0.07, 0.08), BakeryVisuals.LAVENDER)
 elif variant == 1:
  BakeryVisuals.cylinder(head, Vector3(0, 0.35, 0), 0.32, 0.13, clothing)
  BakeryVisuals.ball(head, Vector3(0, 0.46, 0), 0.07, clothing.lightened(0.2))
 elif variant == 3:
  for side in [-1, 1]:
   var frame := BakeryVisuals.ball(head, Vector3(side * 0.13, 0, -0.425), 0.087, Color("#6a536e"))
   frame.scale = Vector3(1, 1, 0.16)
   var lens := BakeryVisuals.ball(head, Vector3(side * 0.13, 0, -0.442), 0.063, Color("#c6ddda"))
   lens.scale.z = 0.12
  BakeryVisuals.box(head, Vector3(0, 0, -0.43), Vector3(0.1, 0.025, 0.02), Color("#6a536e"))
 tray = pivot(body, "TrayVisualRoot", Vector3(0, 0.65, -0.5))
 BakeryVisuals.box(tray, Vector3.ZERO, Vector3(0.81, 0.045, 0.45), BakeryVisuals.LAVENDER)
 for side in [-1, 1]:
  BakeryVisuals.box(tray, Vector3(side * 0.4, 0.035, 0), Vector3(0.035, 0.045, 0.45), BakeryVisuals.LAVENDER.darkened(0.15))
 BakeryVisuals.box(tray, Vector3(0, 0.03, -0.215), Vector3(0.8, 0.04, 0.025), BakeryVisuals.LAVENDER.darkened(0.15))
 cookie_root = pivot(tray, "Cookies", Vector3.ZERO)
 tray.visible = false
 bag = pivot(body, "OrderBag", Vector3(0.34, 0.5, -0.1))
 BakeryVisuals.box(bag, Vector3.ZERO, Vector3(0.23, 0.32, 0.18), BakeryVisuals.CREAM)
 BakeryVisuals.box(bag, Vector3(0, 0.17, 0), Vector3(0.26, 0.035, 0.2), BakeryVisuals.PINK)
 BakeryVisuals.ball(bag, Vector3(0, 0, -0.1), 0.046, BakeryVisuals.CARAMEL)
 bag.visible = false
 if role!="mia":_compact_npc(self)
func show_cookies(count: int):
 show_products({&"COOKIE": count})
func show_products(items: Dictionary):
 for child in cookie_root.get_children():
  cookie_root.remove_child(child)
  child.queue_free()
 var index: int = 0
 for definition in ProductCatalog.all():
  for i in int(items.get(definition.id, 0)):
   var slot := index % 6
   BakeryVisuals.product(cookie_root, Vector3((slot % 3 - 1) * 0.23, 0.055 + floori(index / 6.0) * 0.3, 0.09 - floori(slot / 3.0) * 0.2), definition.id)
   index += 1
 tray.visible = index > 0
func interact():
 interaction_time = 0.38
func set_state(value: StringName):
 state = value
func animate(delta: float):
 if body == null: return
 phase += delta
 interaction_time = maxf(0, interaction_time - delta)
 var active: StringName = &"Interact" if interaction_time > 0 else state
 var walking := active in [&"Walk", &"CarryWalk", &"Leave", &"Happy"]
 var carrying := active in [&"CarryIdle", &"CarryWalk"] or tray.visible
 var pace := phase * (9.0 if walking else 2.0)
 body.position.y = absf(sin(pace)) * 0.055 if walking else sin(pace) * 0.012
 body.rotation.z = sin(pace) * (0.035 if walking else 0.012)
 head.rotation.z = sin(phase * 1.8) * 0.025
 left_leg.rotation.x = sin(pace) * 0.45 if walking else 0.0
 right_leg.rotation.x = -left_leg.rotation.x
 left_arm.rotation.x = 0.95 if carrying else (-sin(pace) * 0.35 if walking else 0.05)
 right_arm.rotation.x = left_arm.rotation.x if carrying else -left_arm.rotation.x
 left_arm.rotation.z = -0.08
 right_arm.rotation.z = 0.08
 if active in [&"Working", &"Serving", &"Interact"]:
  left_arm.rotation.x = 0.8 + sin(phase * 7) * 0.22
  right_arm.rotation.x = 1 + cos(phase * 7) * 0.22
  head.rotation.x = 0.07 + sin(phase * 4) * 0.035
 else: head.rotation.x = 0.0
 if active == &"Happy":
  right_arm.rotation.x = -2.4 + sin(phase * 12) * 0.25
  smile.scale.x = 1.3
 else: smile.scale.x = 1
 bag.visible = active == &"Happy"

 if active == &"Greeting":
  right_arm.rotation.x = -2.5
  right_arm.rotation.z = sin(phase * 9) * 0.3
 if active == &"Talking":
  left_arm.rotation.x = 0.5 + sin(phase * 5) * 0.15
  head.rotation.x = sin(phase * 4) * 0.04
  smile.scale.y = 1.0 + absf(sin(phase * 7)) * 0.6
 else: smile.scale.y = 1.0

func _compact_npc(node:Node):
 for child in node.get_children():
  if not child is MeshInstance3D:_compact_npc(child)
 var shapes:Array=[]
 for child in node.get_children():
  if child is MeshInstance3D:shapes.append(child)
 if shapes.size()<2:return
 var key:String=role+str(clothing)+str(skin)+str(variant)+str(node.name)
 var combined:ArrayMesh
 if npc_meshes.has(key):combined=npc_meshes[key]
 else:
  var groups:Dictionary={}
  for shape in shapes:
   var material:Material=shape.material_override
   if not groups.has(material):
    var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(material);groups[material]=tool
   groups[material].append_from(shape.mesh,0,shape.transform)
  combined=ArrayMesh.new()
  for tool in groups.values():tool.commit(combined)
  npc_meshes[key]=combined
 for shape in shapes:node.remove_child(shape);shape.queue_free()
 var merged:=MeshInstance3D.new();merged.mesh=combined;node.add_child(merged)
