class_name BakeryInterior
extends Node3D
var oven: EquipmentVisual
var checkout: EquipmentVisual
var cook: ChibiVisual
var cashier: ChibiVisual
var decor: Node3D
var collisions: Node3D
const INK = Color("#65516b")
func _ready():
 decor = $VisualRoot
 collisions = $CollisionRoot
 build_shell()
 build_equipment()
 build_decor()
func solid(at: Vector3, size: Vector3, color: Color):
 # Keep physical bounds from stage 1, with geometry in a separate visual tree.
 var body := BakeryVisuals.solid(collisions, at, size, color)
 var geometry := body.get_child(0)
 body.remove_child(geometry)
 decor.add_child(geometry)
 geometry.position = at
func build_shell():
 solid(Vector3(0, -0.15, 0), Vector3(13, 0.3, 11), BakeryVisuals.CREAM)
 for color_index in 2:
  var multimesh := MultiMesh.new()
  multimesh.transform_format = MultiMesh.TRANSFORM_3D
  var tile := BoxMesh.new()
  tile.size = Vector3(0.98, 0.012, 0.98)
  tile.material = BakeryVisuals.material(Color("#eee0cf") if color_index == 0 else BakeryVisuals.CREAM)
  multimesh.mesh = tile
  var positions: Array[Vector3] = []
  for x in range(-6, 7):
   for z in range(-5, 6):
    if posmod(x + z, 2) == color_index: positions.append(Vector3(x, 0.008, z))
  multimesh.instance_count = positions.size()
  for i in positions.size(): multimesh.set_instance_transform(i, Transform3D(Basis(), positions[i]))
  var tiles := MultiMeshInstance3D.new()
  tiles.multimesh = multimesh
  decor.add_child(tiles)
 solid(Vector3(0, 1.2, -5.4), Vector3(13, 2.4, 0.2), BakeryVisuals.PINK)
 solid(Vector3(-6.4, 1.2, 0), Vector3(0.2, 2.4, 11), BakeryVisuals.MINT)
 solid(Vector3(0, 0.18, 5.4), Vector3(13, 0.36, 0.2), BakeryVisuals.CARAMEL)
 solid(Vector3(6.4, 0.18, -1), Vector3(0.2, 0.36, 8.6), BakeryVisuals.CARAMEL)
 solid(Vector3(6.4, 0.18, 5.15), Vector3(0.2, 0.36, 0.5), BakeryVisuals.CARAMEL)
 var threshold := BakeryVisuals.solid(collisions, Vector3(6.4, 0.18, 4.35), Vector3(0.2, 0.36, 1.4), BakeryVisuals.MINT)
 threshold.get_child(0).visible = false
 for y in [0.22, 0.83, 2.4]:
  BakeryVisuals.box(decor, Vector3(0, y, -5.25), Vector3(13, 0.07, 0.08), BakeryVisuals.CREAM)
  BakeryVisuals.box(decor, Vector3(-6.25, y, 0), Vector3(0.08, 0.07, 11), BakeryVisuals.CREAM)
 for x in range(-6, 7): BakeryVisuals.box(decor, Vector3(x, 0.5, -5.25), Vector3(0.035, 0.62, 0.06), BakeryVisuals.CREAM)
 for z in range(-5, 6): BakeryVisuals.box(decor, Vector3(-6.25, 0.5, z), Vector3(0.06, 0.62, 0.035), BakeryVisuals.CREAM)
 for x in [-4.6, 3.9]: window_at(Vector3(x, 1.5, -5.2))
 BakeryVisuals.box(decor, Vector3(-0.4, 1.85, -5.19), Vector3(4.6, 0.94, 0.12), BakeryVisuals.CREAM)
 BakeryVisuals.box(decor, Vector3(-0.4, 1.85, -5.11), Vector3(4.4, 0.77, 0.04), INK)
 var sign_label := BakeryVisuals.label(decor, Vector3(-0.4, 1.87, -5.05), "SWEET EMPIRE", 44)
 sign_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
 sign_label.rotation.y = 0
 sign_label.modulate = BakeryVisuals.CREAM
 sign_label.outline_size = 0
 sign_label.no_depth_test = false
 # Entrance mat and striped runner: decorative only, no new physical obstruction.
 BakeryVisuals.box(decor, Vector3(5.7, 0.03, 4.3), Vector3(1.35, 0.04, 1.3), BakeryVisuals.MINT)
 BakeryVisuals.box(decor, Vector3(5.7, 0.055, 4.3), Vector3(1.17, 0.016, 1.1), Color("#94baaa"))
 for i in 5:
  BakeryVisuals.cylinder(decor, Vector3(2.7, 0.028, 0.7 + i * 0.9), 0.24, 0.027, BakeryVisuals.PINK)
  BakeryVisuals.cylinder(decor, Vector3(2.7, 0.046, 0.7 + i * 0.9), 0.07, 0.012, BakeryVisuals.CREAM)
func window_at(at: Vector3):
 BakeryVisuals.box(decor, at, Vector3(1.8, 1.36, 0.12), BakeryVisuals.CREAM)
 BakeryVisuals.box(decor, at + Vector3(0, 0, 0.075), Vector3(1.58, 1.15, 0.025), Color("#bcd9d9"))
 for dx in [-0.41, 0.41]:
  BakeryVisuals.box(decor, at + Vector3(dx, 0.12, 0.1), Vector3(0.035, 0.88, 0.02), BakeryVisuals.CREAM)
 BakeryVisuals.box(decor, at + Vector3(0, -0.04, 0.1), Vector3(1.6, 0.035, 0.025), BakeryVisuals.CREAM)
 BakeryVisuals.box(decor, at + Vector3(0, -0.72, 0.1), Vector3(2.02, 0.09, 0.4), BakeryVisuals.CARAMEL)
 for i in 7:
  BakeryVisuals.box(decor, at + Vector3(-0.81 + i * 0.27, 0.76, 0.25), Vector3(0.27, 0.24, 0.5), BakeryVisuals.PINK if i % 2 == 0 else BakeryVisuals.CREAM)
func build_equipment():
 oven = preload("res://scenes/visuals/oven.tscn").instantiate()
 add_child(oven)
 oven.position = Vector3(-3.8, 0, -2)
 checkout = preload("res://scenes/visuals/checkout.tscn").instantiate()
 add_child(checkout)
 checkout.position = Vector3(2.7, 0, -1)
 var cook_root := Node3D.new()
 cook_root.name = "CookGameplayRoot"
 add_child(cook_root)
 cook_root.position = Vector3(-3.8, 0, -3.6)
 cook = BakeryVisuals.person(cook_root, BakeryVisuals.CREAM, true, Color("#e5b48f"), 0, "cook")
 cook.rotation.y = PI
 var cashier_root := Node3D.new()
 cashier_root.name = "CashierGameplayRoot"
 add_child(cashier_root)
 cashier_root.position = Vector3(2.7, 0, -2.35)
 cashier = BakeryVisuals.person(cashier_root, BakeryVisuals.CREAM, false, Color("#ca987a"), 0, "cashier")
 cashier.rotation.y = PI
 solid(Vector3(-1.4, 0.45, -3.7), Vector3(1.7, 0.9, 0.85), BakeryVisuals.MINT)
 BakeryVisuals.box(decor, Vector3(-1.4, 0.95, -3.7), Vector3(1.85, 0.12, 1), BakeryVisuals.CREAM)
 BakeryVisuals.cylinder(decor, Vector3(-1.9, 1.08, -3.7), 0.16, 0.16, BakeryVisuals.LAVENDER)
 BakeryVisuals.cylinder(decor, Vector3(-1.9, 1.18, -3.7), 0.13, 0.025, Color("#e1bc8c"))
 BakeryVisuals.box(decor, Vector3(-1.2, 1.05, -3.6), Vector3(0.48, 0.03, 0.35), BakeryVisuals.CARAMEL)
 BakeryVisuals.cookie(decor, Vector3(-1.2, 1.1, -3.6))
func plant(at: Vector3, size: float = 1):
 var root := Node3D.new()
 decor.add_child(root)
 root.position = at
 root.scale = Vector3.ONE * size
 BakeryVisuals.cylinder(root, Vector3(0, 0.22, 0), 0.23, 0.44, BakeryVisuals.CARAMEL)
 BakeryVisuals.cylinder(root, Vector3(0, 0.44, 0), 0.26, 0.07, BakeryVisuals.CREAM)
 for i in 5:
  var angle := i * TAU / 5
  var leaf := BakeryVisuals.ball(root, Vector3(sin(angle) * 0.2, 0.7 + (i % 2) * 0.12, cos(angle) * 0.2), 0.19, Color("#91b69d") if i % 2 == 0 else BakeryVisuals.MINT)
  leaf.scale = Vector3(0.8, 1.7, 0.55)
  leaf.rotation.z = sin(angle) * -0.4
func jar(at: Vector3, color: Color):
 BakeryVisuals.cylinder(decor, at, 0.11, 0.25, BakeryVisuals.CREAM)
 BakeryVisuals.cylinder(decor, at + Vector3(0, 0.14, 0), 0.12, 0.04, color)
 BakeryVisuals.box(decor, at + Vector3(0, 0, 0.105), Vector3(0.13, 0.11, 0.018), color)
func package(at: Vector3, color: Color):
 BakeryVisuals.box(decor, at, Vector3(0.46, 0.27, 0.35), color)
 BakeryVisuals.box(decor, at + Vector3(0, 0.14, 0), Vector3(0.49, 0.035, 0.38), color.lightened(0.12))
 BakeryVisuals.box(decor, at + Vector3(0, 0, 0.185), Vector3(0.055, 0.3, 0.015), BakeryVisuals.CREAM)
func build_decor():
 # Wall-side decor stays away from the oven-to-checkout route and queue corridor.
 for y in [1.15, 1.95]:
  BakeryVisuals.box(decor, Vector3(-6.03, y, -1.3), Vector3(0.55, 0.09, 2.6), BakeryVisuals.CARAMEL)
  for i in 6: jar(Vector3(-5.92, y + 0.18, -2.35 + i * 0.42), [BakeryVisuals.PINK, BakeryVisuals.MINT, BakeryVisuals.LAVENDER][i % 3])
 for z in [-2.45, -0.15]:
  BakeryVisuals.box(decor, Vector3(-6.08, 1.55, z), Vector3(0.12, 1.0, 0.07), BakeryVisuals.CREAM)
 for x in [-0.9, -0.25, 0.4]:
  package(Vector3(x, 0.2, -4.9), BakeryVisuals.PINK)
  package(Vector3(x, 0.49, -4.9), BakeryVisuals.CREAM)
 plant(Vector3(-5.5, 0, -4.6))
 plant(Vector3(5.45, 0, -4.6), 1.2)
 plant(Vector3(-5.55, 0, 4.6), 0.85)
 # Pastry display against the right back wall: opaque frames, open sides (no costly transparency).
 BakeryVisuals.box(decor, Vector3(5.4, 0.48, -2.55), Vector3(1.22, 0.9, 1.8), BakeryVisuals.MINT)
 for y in [0.95, 1.42]:
  BakeryVisuals.box(decor, Vector3(5.4, y, -2.55), Vector3(1.34, 0.07, 1.9), BakeryVisuals.CREAM)
  for z in [-3, -2.45, -2]:
   BakeryVisuals.cookie(decor, Vector3(5.2, y + 0.07, z))
   BakeryVisuals.cookie(decor, Vector3(5.6, y + 0.07, z))
 for x in [4.82, 5.98]:
  for z in [-3.38, -1.72]: BakeryVisuals.box(decor, Vector3(x, 1.2, z), Vector3(0.04, 0.5, 0.04), BakeryVisuals.CARAMEL)
 # Small reading corner on the unused left side.
 var table_at := Vector3(-4.65, 0, 2.5)
 BakeryVisuals.cylinder(decor, table_at + Vector3(0, 0.71, 0), 0.6, 0.1, BakeryVisuals.CARAMEL)
 BakeryVisuals.cylinder(decor, table_at + Vector3(0, 0.35, 0), 0.08, 0.7, BakeryVisuals.CREAM)
 BakeryVisuals.cylinder(decor, table_at + Vector3(0, 0.06, 0), 0.34, 0.08, BakeryVisuals.CREAM)
 BakeryVisuals.cylinder(decor, table_at + Vector3(0, 0.83, 0), 0.09, 0.14, BakeryVisuals.CREAM)
 BakeryVisuals.ball(decor, table_at + Vector3(0, 1, 0), 0.11, BakeryVisuals.PINK)
 for z in [1.5, 3.5]:
  BakeryVisuals.cylinder(decor, Vector3(-4.65, 0.4, z), 0.31, 0.09, BakeryVisuals.PINK)
  for x in [-4.85, -4.45]:
   for dz in [-0.17, 0.17]: BakeryVisuals.box(decor, Vector3(x, 0.2, z + dz), Vector3(0.05, 0.4, 0.05), BakeryVisuals.CARAMEL)
  BakeryVisuals.box(decor, Vector3(-4.65, 0.69, z + (-0.25 if z < 2 else 0.25)), Vector3(0.55, 0.45, 0.07), BakeryVisuals.MINT)
 # Wall art, a clock and warm pendant shades; only one actual directional light.
 BakeryVisuals.box(decor, Vector3(-6.18, 1.52, 2.6), Vector3(0.09, 1.03, 1.1), BakeryVisuals.CARAMEL)
 BakeryVisuals.box(decor, Vector3(-6.12, 1.52, 2.6), Vector3(0.035, 0.86, 0.93), BakeryVisuals.CREAM)
 var painting := BakeryVisuals.ball(decor, Vector3(-6.08, 1.58, 2.6), 0.23, BakeryVisuals.PINK)
 painting.scale.x = 0.15
 BakeryVisuals.box(decor, Vector3(-6.05, 1.34, 2.6), Vector3(0.025, 0.2, 0.34), BakeryVisuals.CARAMEL)
 var clock := BakeryVisuals.cylinder(decor, Vector3(1.85, 1.9, -5.11), 0.28, 0.06, BakeryVisuals.CARAMEL)
 clock.rotation_degrees.x = 90
 var face := BakeryVisuals.cylinder(decor, Vector3(1.85, 1.9, -5.06), 0.24, 0.025, BakeryVisuals.CREAM)
 face.rotation_degrees.x = 90
 BakeryVisuals.box(decor, Vector3(1.85, 1.96, -5.03), Vector3(0.025, 0.15, 0.025), INK)
 BakeryVisuals.box(decor, Vector3(1.91, 1.9, -5.03), Vector3(0.14, 0.025, 0.025), INK)
 for x in [-2.3, 3.8]:
  BakeryVisuals.cylinder(decor, Vector3(x, 2.95, -3.9), 0.025, 0.65, INK)
  var shade := CylinderMesh.new()
  shade.top_radius = 0.13
  shade.bottom_radius = 0.4
  shade.height = 0.32
  shade.radial_segments = 12
  BakeryVisuals.shape(decor, Vector3(x, 2.54, -3.9), shade, BakeryVisuals.CARAMEL)
  BakeryVisuals.cylinder(decor, Vector3(x, 2.38, -3.9), 0.33, 0.025, BakeryVisuals.CREAM)

func open_expansion_passage():
 for body in collisions.get_children():
  if body.position.is_equal_approx(Vector3(0, 1.2, -5.4)):
   for child in body.get_children():
    if child is CollisionShape3D: child.set_deferred("disabled", true)
 for item in decor.get_children():
  if item.position.is_equal_approx(Vector3(0, 1.2, -5.4)): item.hide()
  if is_equal_approx(item.position.z, -5.25) and absf(item.position.x) < 1.6: item.hide()
  if item.position.z < -4.7 and absf(item.position.x) < 1.7 and item.position.y < 1.1: item.hide()
  if item.position.z < -5.0 and absf(item.position.x + 0.4) < 0.1 and item.position.y > 1.5: item.position.y += 0.8
 for x in [-4.1, 4.1]: solid(Vector3(x, 1.2, -5.4), Vector3(4.8, 2.4, 0.2), BakeryVisuals.PINK)
 BakeryVisuals.box(decor, Vector3(0, 2.4, -5.4), Vector3(3.4, 0.18, 0.28), BakeryVisuals.CREAM)
