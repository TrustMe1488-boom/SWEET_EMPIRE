class_name ExpansionZone
extends Node3D
var zone: int = 2
var back_wall: StaticBody3D
var back_visual: MeshInstance3D
func _ready():
 var visual: Node3D = $VisualRoot
 var physical: Node3D = $CollisionRoot
 _solid(physical, visual, Vector3(0, -0.15, 0), Vector3(13, 0.3, 5.2), BakeryVisuals.CREAM)
 _solid(physical, visual, Vector3(-6.4, 1.2, 0), Vector3(0.2, 2.4, 5), BakeryVisuals.MINT)
 _solid(physical, visual, Vector3(6.4, 0.18, 0), Vector3(0.2, 0.36, 5), BakeryVisuals.CARAMEL)
 back_wall = _solid(physical, visual, Vector3(0, 1.2, -2.4), Vector3(13, 2.4, 0.2), BakeryVisuals.PINK)
 back_visual = visual.get_child(visual.get_child_count() - 1)
 var tiles := MultiMesh.new()
 tiles.transform_format = MultiMesh.TRANSFORM_3D
 var mesh := BoxMesh.new()
 mesh.size = Vector3(0.98, 0.02, 0.98)
 mesh.material = BakeryVisuals.material(Color("#eee0cf"))
 tiles.mesh = mesh
 var positions: Array[Vector3] = []
 for x in range(-6, 7):
  for z in range(-2, 3):
   if posmod(x + z, 2) == 0: positions.append(Vector3(x, 0.015, z))
 tiles.instance_count = positions.size()
 for i in positions.size(): tiles.set_instance_transform(i, Transform3D(Basis(), positions[i]))
 var floor_tiles := MultiMeshInstance3D.new()
 floor_tiles.multimesh = tiles
 visual.add_child(floor_tiles)
 for y in [0.25, 0.85, 2.4]: BakeryVisuals.box(visual, Vector3(-6.25, y, 0), Vector3(0.06, 0.06, 5), BakeryVisuals.CREAM)
 BakeryVisuals.label(visual, Vector3(-4.8, 2.3, -2.2), "КОФЕ И КАПКЕЙКИ" if zone == 2 else "ТОРТЫ", 25)
func _solid(physical: Node3D, visual: Node3D, at: Vector3, size: Vector3, color: Color) -> StaticBody3D:
 var body := BakeryVisuals.solid(physical, at, size, color)
 var geometry := body.get_child(0)
 body.remove_child(geometry)
 visual.add_child(geometry)
 geometry.position = at
 return body
func open_passage():
 back_wall.get_child(0).set_deferred("disabled", true)
 back_visual.hide()
 for x in [-4.1, 4.1]: _solid($CollisionRoot, $VisualRoot, Vector3(x, 1.2, -2.4), Vector3(4.8, 2.4, 0.2), BakeryVisuals.PINK)
 BakeryVisuals.box($VisualRoot, Vector3(0, 2.4, -2.4), Vector3(3.4, 0.18, 0.28), BakeryVisuals.CREAM)
