class_name BakeryVisuals
extends RefCounted
const PINK = Color("#F3C5D5")
const MINT = Color("#B9DDD0")
const CREAM = Color("#FFF2DE")
const LAVENDER = Color("#BBA6D7")
const CARAMEL = Color("#D8A477")
static var dessert_style: CosmeticStyle
static var product_group: int = 0
static var materials: Dictionary = {}
static func material(color: Color) -> StandardMaterial3D:
 if materials.has(color): return materials[color]
 var mat := StandardMaterial3D.new()
 mat.albedo_color = color
 mat.roughness = 0.95
 mat.metallic_specular = 0.15
 materials[color] = mat
 return mat
static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var mesh := BoxMesh.new()
 mesh.size = size
 return shape(parent, at, mesh, color)
static func shape(parent: Node3D, at: Vector3, mesh: PrimitiveMesh, color: Color) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.mesh = mesh
 node.material_override = material(color)
 parent.add_child(node)
 node.position = at
 return node
static func ball(parent: Node3D, at: Vector3, radius: float, color: Color) -> MeshInstance3D:
 var mesh := SphereMesh.new()
 mesh.radius = radius
 mesh.height = radius * 2
 mesh.radial_segments = 12
 mesh.rings = 6
 return shape(parent, at, mesh, color)
static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
 var mesh := CylinderMesh.new()
 mesh.top_radius = radius
 mesh.bottom_radius = radius
 mesh.height = height
 mesh.radial_segments = 12
 return shape(parent, at, mesh, color)
static func solid(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
 var body := StaticBody3D.new()
 parent.add_child(body)
 body.position = at
 box(body, Vector3.ZERO, size, color)
 var collider := CollisionShape3D.new()
 var shape_box := BoxShape3D.new()
 shape_box.size = size
 collider.shape = shape_box
 body.add_child(collider)
 return body
static func label(parent: Node3D, at: Vector3, text: String, font_size: int = 32) -> Label3D:
 var node := Label3D.new()
 node.text = text
 node.font_size = font_size
 node.pixel_size = 0.009
 node.modulate = Color("#51415f")
 node.outline_modulate = CREAM
 node.outline_size = 8
 node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 node.no_depth_test = true
 parent.add_child(node)
 node.position = at
 return node
static func person(parent: Node3D, color: Color, chef: bool = false, skin: Color = Color("#edc1a0"), variant: int = 0, role: String = "") -> ChibiVisual:
 var model: ChibiVisual = load("res://scenes/visuals/chibi_character.tscn").instantiate()
 model.clothing = color
 model.skin = skin
 model.variant = variant
 model.role = role if not role.is_empty() else ("mia" if chef else "customer")
 parent.add_child(model)
 return model
static func _classic_cookie(parent: Node3D, at: Vector3):
 var rim := cylinder(parent, at, 0.135, 0.065, CARAMEL.darkened(0.14))
 rim.rotation.y = 0.17
 cylinder(parent, at + Vector3(0, 0.022, 0), 0.12, 0.04, Color("#e6b57d"))
 for offset in [Vector3(-0.045, 0.049, 0.035), Vector3(0.05, 0.049, -0.025), Vector3(-0.015, 0.049, -0.065), Vector3(0.04, 0.049, 0.07)]:
  var chip := box(parent, at + offset, Vector3(0.035, 0.018, 0.029), Color("#674632"))
  chip.rotation.y = offset.x * 27

static func _classic_product(parent: Node3D, at: Vector3, id: StringName):
 match id:
  &"COOKIE": _classic_cookie(parent, at)
  &"COFFEE":
   cylinder(parent, at + Vector3(0, 0.11, 0), 0.09, 0.22, CREAM)
   cylinder(parent, at + Vector3(0, 0.105, 0), 0.094, 0.09, MINT)
   cylinder(parent, at + Vector3(0, 0.235, 0), 0.102, 0.04, Color("#755347"))
   box(parent, at + Vector3(0.04, 0.259, 0), Vector3(0.035, 0.01, 0.016), CREAM)
  &"CUPCAKE":
   cylinder(parent, at + Vector3(0, 0.06, 0), 0.11, 0.12, LAVENDER)
   for offset in [Vector3(-0.045, 0.15, 0), Vector3(0.045, 0.15, 0), Vector3(0, 0.21, 0)]: ball(parent, at + offset, 0.085, PINK)
   ball(parent, at + Vector3(0, 0.28, 0), 0.034, Color("#b9667d"))
  &"CAKE":
   cylinder(parent, at + Vector3(0, 0.085, 0), 0.135, 0.17, CARAMEL)
   cylinder(parent, at + Vector3(0, 0.09, 0), 0.137, 0.04, PINK)
   cylinder(parent, at + Vector3(0, 0.18, 0), 0.14, 0.04, CREAM)
   for x in [-0.065, 0.065]: ball(parent, at + Vector3(x, 0.22, 0), 0.036, Color("#c7768a"))

static func cookie(parent: Node3D, at: Vector3, override_style: CosmeticStyle = null):
 product(parent,at,&"COOKIE",override_style)
static func product(parent: Node3D, at: Vector3, id: StringName, override_style: CosmeticStyle = null):
 var style: CosmeticStyle=override_style if override_style!=null else dessert_style
 var first:=parent.get_child_count()
 if style==null or style.detail=="classic":_classic_product(parent,at,id)
 else:CosmeticProductVisual.build(parent,at,id,style)
 product_group+=1
 for i in range(first,parent.get_child_count()):
  var child:=parent.get_child(i)
  child.set_meta("cosmetic_product_id",id)
  child.set_meta("cosmetic_product_group",product_group)
  child.set_meta("cosmetic_product_origin",at)
