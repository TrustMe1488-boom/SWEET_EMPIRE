class_name EquipmentVisual
extends Node3D
@export_enum("oven", "checkout", "coffee", "cupcake", "cake") var kind: String = "oven"
var running: bool = false
var progress: float = 0.0
var time: float = 0.0
var cookies: Node3D
var led: MeshInstance3D
var progress_fill: MeshInstance3D
var steam: Array[MeshInstance3D] = []
func _ready():
 var root: Node3D = $VisualRoot
 var collision: Node3D = $CollisionRoot
 var body := StaticBody3D.new()
 collision.add_child(body)
 var shape := CollisionShape3D.new()
 var bounds := BoxShape3D.new()
 bounds.size = Vector3(1.65, 1.24, 1.35) if kind != "checkout" else Vector3(1.7, 1, 1.25)
 shape.shape = bounds
 shape.position.y = 0.62 if kind != "checkout" else 0.5
 body.add_child(shape)
 match kind:
  "oven": build_oven(root)
  "checkout": build_checkout(root)
  _: build_dessert_station(root)
 if not root.has_node("CustomizationRoot"):
  var socket := Node3D.new()
  socket.name = "CustomizationRoot"
  root.add_child(socket)
 var customization: Node3D = root.get_node("CustomizationRoot")
 for title in ["LogoSocket", "TopSocket"]:
  var marker := Marker3D.new()
  marker.name = title
  marker.position = Vector3(0, 0.55, 0.75) if title == "LogoSocket" else Vector3(0, 1.25, -0.5)
  customization.add_child(marker)
func build_oven(root: Node3D):
 BakeryVisuals.box(root, Vector3(0, 0.65, 0), Vector3(1.65, 1.18, 1.35), BakeryVisuals.LAVENDER)
 BakeryVisuals.box(root, Vector3(0, 0.18, 0), Vector3(1.7, 0.2, 1.4), Color("#7e6c91"))
 BakeryVisuals.box(root, Vector3(0, 1.28, 0), Vector3(1.78, 0.13, 1.46), BakeryVisuals.CREAM)
 for x in [-0.7, 0.7]:
  BakeryVisuals.box(root, Vector3(x, 0.1, 0.38), Vector3(0.14, 0.2, 0.18), Color("#796473"))
  BakeryVisuals.box(root, Vector3(x, 0.1, -0.38), Vector3(0.14, 0.2, 0.18), Color("#796473"))
 BakeryVisuals.box(root, Vector3(0, 0.63, 0.697), Vector3(1.43, 0.81, 0.08), BakeryVisuals.CREAM)
 BakeryVisuals.box(root, Vector3(0, 0.59, 0.745), Vector3(1.18, 0.51, 0.045), Color("#62516a"))
 BakeryVisuals.box(root, Vector3(0, 0.6, 0.772), Vector3(1.01, 0.35, 0.025), Color("#d99b69"))
 BakeryVisuals.box(root, Vector3(0, 0.52, 0.79), Vector3(1.04, 0.045, 0.05), Color("#8d6570"))
 for x in [-0.3, 0, 0.3]: BakeryVisuals.cookie(root, Vector3(x, 0.55, 0.7))
 for x in [-0.55, 0.55]: BakeryVisuals.box(root, Vector3(x, 0.98, 0.8), Vector3(0.09, 0.08, 0.16), Color("#967383"))
 BakeryVisuals.box(root, Vector3(0, 0.99, 0.87), Vector3(1.2, 0.065, 0.08), BakeryVisuals.CARAMEL)
 BakeryVisuals.box(root, Vector3(0, 1.14, 0.71), Vector3(1.5, 0.17, 0.07), Color("#8d779b"))
 BakeryVisuals.box(root, Vector3(-0.25, 1.15, 0.76), Vector3(0.52, 0.1, 0.025), Color("#514258"))
 progress_fill = BakeryVisuals.box(root, Vector3(-0.25, 1.15, 0.78), Vector3(0.46, 0.05, 0.016), BakeryVisuals.MINT)
 for x in [0.28, 0.58]:
  var knob := BakeryVisuals.cylinder(root, Vector3(x, 1.15, 0.77), 0.062, 0.06, BakeryVisuals.CREAM)
  knob.rotation_degrees.x = 90
  BakeryVisuals.box(root, Vector3(x, 1.18, 0.81), Vector3(0.012, 0.035, 0.015), Color("#796473"))
 led = BakeryVisuals.ball(root, Vector3(-0.65, 1.15, 0.78), 0.035, BakeryVisuals.MINT)
 for z in [-0.4, -0.1, 0.2]:
  BakeryVisuals.box(root, Vector3(0.835, 0.71, z), Vector3(0.016, 0.045, 0.18), Color("#8d779b"))
 # Ready cookies sit on a separate reusable tray, not in an inventory-owned mesh.
 BakeryVisuals.box(root, Vector3(0, 1.37, 0.08), Vector3(1.32, 0.045, 0.88), Color("#8d779b"))
 for side in [-1, 1]: BakeryVisuals.box(root, Vector3(side * 0.65, 1.41, 0.08), Vector3(0.03, 0.07, 0.88), Color("#8d779b"))
 cookies = Node3D.new()
 cookies.name = "ReadyCookies"
 root.add_child(cookies)
 for i in 3:
  var puff := BakeryVisuals.ball(root, Vector3(-0.5 + i * 0.5, 1.65, -0.4), 0.055, BakeryVisuals.CREAM)
  steam.append(puff)
func build_checkout(root: Node3D):
 BakeryVisuals.box(root, Vector3(0, 0.5, 0), Vector3(1.7, 1, 1.25), BakeryVisuals.MINT)
 BakeryVisuals.box(root, Vector3(0, 0.15, 0), Vector3(1.74, 0.13, 1.28), Color("#7fa797"))
 for x in [-0.55, 0, 0.55]:
  BakeryVisuals.box(root, Vector3(x, 0.55, 0.635), Vector3(0.45, 0.56, 0.025), BakeryVisuals.MINT.lightened(0.15))
 BakeryVisuals.box(root, Vector3(0, 1.05, 0), Vector3(1.94, 0.14, 1.45), BakeryVisuals.CARAMEL)
 BakeryVisuals.box(root, Vector3(0, 1.13, 0), Vector3(1.9, 0.025, 1.41), BakeryVisuals.CREAM)
 BakeryVisuals.box(root, Vector3(0.36, 1.23, -0.08), Vector3(0.58, 0.16, 0.5), Color("#8e789d"))
 BakeryVisuals.box(root, Vector3(0.36, 1.33, 0.03), Vector3(0.48, 0.045, 0.3), BakeryVisuals.CREAM)
 for x in range(3):
  for z in range(2): BakeryVisuals.box(root, Vector3(0.22 + x * 0.13, 1.36, -0.05 + z * 0.1), Vector3(0.075, 0.018, 0.06), BakeryVisuals.LAVENDER)
 BakeryVisuals.box(root, Vector3(0.36, 1.5, -0.23), Vector3(0.07, 0.32, 0.07), Color("#8e789d"))
 BakeryVisuals.box(root, Vector3(0.36, 1.69, -0.23), Vector3(0.58, 0.36, 0.09), Color("#6f5b7c"))
 BakeryVisuals.box(root, Vector3(0.36, 1.69, -0.173), Vector3(0.49, 0.26, 0.02), BakeryVisuals.MINT)
 for i in 3: BakeryVisuals.box(root, Vector3(0.36, 1.75 - i * 0.06, -0.158), Vector3(0.28 - i * 0.06, 0.018, 0.01), Color("#6f9b8c"))
 BakeryVisuals.box(root, Vector3(-0.5, 1.17, 0.14), Vector3(0.62, 0.04, 0.57), BakeryVisuals.LAVENDER)
 BakeryVisuals.box(root, Vector3(-0.5, 1.2, 0.14), Vector3(0.55, 0.02, 0.49), BakeryVisuals.CREAM)
 var pack := BakeryVisuals.box(root, Vector3(-0.5, 1.32, 0.1), Vector3(0.34, 0.2, 0.28), BakeryVisuals.PINK)
 pack.rotation.y = 0.2
 BakeryVisuals.box(root, Vector3(-0.5, 1.43, 0.1), Vector3(0.04, 0.025, 0.3), BakeryVisuals.CREAM)
 BakeryVisuals.cylinder(root, Vector3(0.7, 1.22, 0.43), 0.09, 0.15, BakeryVisuals.CARAMEL)
 BakeryVisuals.ball(root, Vector3(0.7, 1.38, 0.43), 0.11, BakeryVisuals.PINK)
func animate(delta: float):
 time += delta
 if kind == "checkout" or led == null: return
 progress_fill.scale.x = maxf(0.03, progress)
 led.scale = Vector3.ONE * (1 + sin(time * 5) * 0.15 if running else 0.8)
 for i in steam.size():
  var puff := steam[i]
  var cycle := fmod(time * 0.55 + i * 0.33, 1.0)
  puff.visible = running
  puff.position.y = 1.55 + cycle * 0.65
  puff.scale = Vector3.ONE * sin(cycle * PI)

func build_dessert_station(root: Node3D):
 var color: Color = BakeryVisuals.MINT if kind == "coffee" else (BakeryVisuals.PINK if kind == "cupcake" else BakeryVisuals.LAVENDER)
 BakeryVisuals.box(root, Vector3(0, 0.56, 0), Vector3(1.65, 1.12, 1.35), color)
 BakeryVisuals.box(root, Vector3(0, 0.1, 0), Vector3(1.7, 0.16, 1.4), color.darkened(0.18))
 BakeryVisuals.box(root, Vector3(0, 1.17, 0), Vector3(1.82, 0.12, 1.48), BakeryVisuals.CREAM)
 for x in [-0.5, 0.5]:
  BakeryVisuals.box(root, Vector3(x, 0.57, 0.69), Vector3(0.6, 0.65, 0.03), color.lightened(0.12))
  BakeryVisuals.box(root, Vector3(x, 0.72, 0.73), Vector3(0.21, 0.04, 0.06), BakeryVisuals.CARAMEL)
 BakeryVisuals.box(root, Vector3(0, 1.28, 0.4), Vector3(1.3, 0.035, 0.48), color.darkened(0.2))
 cookies = Node3D.new()
 cookies.name = "ReadyProducts"
 root.add_child(cookies)
 if kind == "coffee":
  BakeryVisuals.box(root, Vector3(0, 1.65, -0.28), Vector3(1.16, 0.82, 0.53), color.darkened(0.09))
  BakeryVisuals.box(root, Vector3(0, 1.67, 0.015), Vector3(0.86, 0.4, 0.05), Color("#65516b"))
  for x in [-0.27, 0.27]:
   BakeryVisuals.cylinder(root, Vector3(x, 1.47, 0.07), 0.055, 0.14, BakeryVisuals.CARAMEL)
   BakeryVisuals.cylinder(root, Vector3(x, 2.16, -0.3), 0.18, 0.22, BakeryVisuals.CARAMEL)
   BakeryVisuals.cylinder(root, Vector3(x, 2.29, -0.3), 0.19, 0.03, Color("#65516b"))
  BakeryVisuals.box(root, Vector3(0, 1.94, 0.04), Vector3(0.36, 0.12, 0.025), Color("#65516b"))
 elif kind == "cupcake":
  BakeryVisuals.cylinder(root, Vector3(-0.4, 1.35, -0.2), 0.26, 0.22, BakeryVisuals.LAVENDER)
  BakeryVisuals.cylinder(root, Vector3(-0.4, 1.47, -0.2), 0.22, 0.025, BakeryVisuals.PINK)
  BakeryVisuals.box(root, Vector3(-0.7, 1.62, -0.2), Vector3(0.13, 0.75, 0.2), BakeryVisuals.CREAM)
  BakeryVisuals.box(root, Vector3(-0.48, 1.98, -0.2), Vector3(0.56, 0.18, 0.29), BakeryVisuals.CREAM)
  BakeryVisuals.cylinder(root, Vector3(-0.4, 1.65, -0.2), 0.025, 0.46, BakeryVisuals.CARAMEL)
  for x in [0.25, 0.55]: BakeryVisuals.cylinder(root, Vector3(x, 1.38, -0.25), 0.09, 0.31, BakeryVisuals.CREAM)
 else:
  BakeryVisuals.cylinder(root, Vector3(0, 1.32, -0.27), 0.12, 0.18, BakeryVisuals.CARAMEL)
  BakeryVisuals.cylinder(root, Vector3(0, 1.43, -0.27), 0.42, 0.05, BakeryVisuals.CREAM)
  var sample := Node3D.new()
  root.add_child(sample)
  sample.position = Vector3(0, 1.48, -0.27)
  sample.scale = Vector3.ONE * 2
  BakeryVisuals.product(sample, Vector3.ZERO, &"CAKE")
  BakeryVisuals.box(root, Vector3(0.6, 1.36, -0.3), Vector3(0.16, 0.28, 0.28), BakeryVisuals.PINK)
 led = BakeryVisuals.ball(root, Vector3(0.65, 1.04, 0.72), 0.045, BakeryVisuals.MINT)
 BakeryVisuals.box(root, Vector3(0, 1.04, 0.7), Vector3(0.8, 0.11, 0.02), Color("#65516b"))
 progress_fill = BakeryVisuals.box(root, Vector3(0, 1.04, 0.72), Vector3(0.7, 0.05, 0.025), BakeryVisuals.CREAM)
