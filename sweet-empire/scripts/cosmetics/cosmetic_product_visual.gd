class_name CosmeticProductVisual
extends RefCounted
static var meshes: Dictionary = {}
static func build(parent: Node3D, at: Vector3, id: StringName, style: CosmeticStyle) -> Node3D:
 var root := Node3D.new()
 root.name = "StyledProduct"
 parent.add_child(root)
 root.position = at
 var key:=str(id)+":"+str(style.get_instance_id())
 if meshes.has(key):
  var cached:=MeshInstance3D.new();cached.mesh=meshes[key];root.add_child(cached)
  return root
 var festive := style.detail == "festive"
 var icing := style.secondary
 match id:
  &"COOKIE":
   BakeryVisuals.cylinder(root,Vector3(0,0.01,0),0.14,0.065,style.primary)
   BakeryVisuals.cylinder(root,Vector3(0,0.049,0),0.122,0.021,icing)
   for i in 5:
    var angle := i * TAU / 5
    var chip := BakeryVisuals.box(root,Vector3(cos(angle)*0.075,0.066,sin(angle)*0.075),Vector3(0.035,0.018,0.025),style.accent if i%2==0 else style.trim)
    chip.rotation.y=angle
  &"COFFEE":
   BakeryVisuals.cylinder(root,Vector3(0,0.11,0),0.11,0.21,style.primary)
   BakeryVisuals.cylinder(root,Vector3(0,0.1,0),0.114,0.065,style.secondary)
   BakeryVisuals.cylinder(root,Vector3(0,0.225,0),0.12,0.035,style.trim)
   for i in 3: BakeryVisuals.ball(root,Vector3(0,0.245+i*0.025,0),0.075-i*0.017,icing)
   var straw:=BakeryVisuals.cylinder(root,Vector3(0.065,0.29,0),0.013,0.16,style.accent)
   straw.rotation.z=-0.2
   BakeryVisuals.ball(root,Vector3(0,0.12,-0.115),0.032,style.trim)
  &"CUPCAKE":
   BakeryVisuals.cylinder(root,Vector3(0,0.065,0),0.115,0.13,style.primary)
   for i in 8:
    var angle:=i*TAU/8
    BakeryVisuals.box(root,Vector3(cos(angle)*0.108,0.06,sin(angle)*0.108),Vector3(0.018,0.09,0.018),style.trim)
   for i in 3: BakeryVisuals.ball(root,Vector3(0,0.15+i*0.045,0),0.12-i*0.025,icing)
   BakeryVisuals.ball(root,Vector3(0,0.3,0),0.035,style.accent)
  &"CAKE":
   BakeryVisuals.cylinder(root,Vector3(0,0.07,0),0.145,0.14,style.primary)
   BakeryVisuals.cylinder(root,Vector3(0,0.14,0),0.15,0.035,style.trim)
   BakeryVisuals.cylinder(root,Vector3(0,0.2,0),0.105,0.105,icing)
   BakeryVisuals.cylinder(root,Vector3(0,0.256,0),0.112,0.025,style.trim)
   for i in 6:
    var angle:=i*TAU/6
    BakeryVisuals.ball(root,Vector3(cos(angle)*0.12,0.17,sin(angle)*0.12),0.025,style.accent)
   if festive:
    for x in [-0.04,0.04]:
     BakeryVisuals.cylinder(root,Vector3(x,0.31,0),0.012,0.085,style.primary)
     BakeryVisuals.ball(root,Vector3(x,0.365,0),0.019,Color("#EDC27D"))
   else: BakeryVisuals.ball(root,Vector3(0,0.3,0),0.04,style.accent)
 if festive and id != &"COOKIE":
  for i in 6:
   var angle:=i*TAU/6
   var sprinkle:=BakeryVisuals.box(root,Vector3(cos(angle)*0.063,0.275 if id==&"CAKE" else 0.23,sin(angle)*0.063),Vector3(0.025,0.013,0.016),[style.primary,style.accent,style.trim][i%3])
   sprinkle.rotation.y=angle
 var groups: Dictionary = {}
 for child in root.get_children():
  if child is MeshInstance3D:
   var material: Material=child.material_override
   if not groups.has(material):
    var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(material)
    groups[material]=tool
   groups[material].append_from(child.mesh,0,child.transform)
 var combined:=ArrayMesh.new()
 for tool in groups.values():tool.commit(combined)
 for child in root.get_children():root.remove_child(child);child.queue_free()
 var instance:=MeshInstance3D.new();instance.mesh=combined;root.add_child(instance)
 meshes[key]=combined
 return root
