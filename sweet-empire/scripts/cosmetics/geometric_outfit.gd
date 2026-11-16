class_name GeometricOutfit
extends RefCounted
static func reset(model:ChibiVisual):
 for child in model.head.get_children():
  if child is MeshInstance3D and child.position.y>=0.3:child.visible=true
 for parent in [model.head,model.left_arm,model.right_arm]:
  var root:Node=parent.get_node_or_null("GeometricCostume")
  if root!=null:parent.remove_child(root);root.queue_free()
static func build(model:ChibiVisual,style:CosmeticStyle,body:Node3D)->bool:
 if style.detail not in ["maid","royal","winter"]:return false
 for child in model.head.get_children():
  if child is MeshInstance3D and child.position.y>=0.3:child.hide()
 var old_band:=model.head.get_node_or_null("CosmeticHatBand")
 if old_band!=null:
  for child in old_band.get_children():old_band.remove_child(child);child.queue_free()
 var hat:=Node3D.new();hat.name="GeometricCostume";model.head.add_child(hat)
 for arm in [model.left_arm,model.right_arm]:
  var sleeve:=Node3D.new();sleeve.name="GeometricCostume";arm.add_child(sleeve)
  BakeryVisuals.ball(sleeve,Vector3(0,-0.07,0),0.17,style.primary)
 if style.detail=="maid":
  var skirt:=CylinderMesh.new();skirt.top_radius=0.24;skirt.bottom_radius=0.4;skirt.height=0.42;skirt.radial_segments=12
  BakeryVisuals.shape(body,Vector3(0,0.49,0),skirt,style.primary)
  BakeryVisuals.box(body,Vector3(0,0.48,-0.35),Vector3(0.38,0.29,0.035),style.secondary)
  for i in 7:BakeryVisuals.ball(hat,Vector3(-0.24+i*0.08,0.34,-0.12),0.06,style.secondary)
 elif style.detail=="royal":
  BakeryVisuals.cylinder(hat,Vector3(0,0.35,0),0.25,0.1,style.trim)
  for i in 5:
   var angle:=i*TAU/5
   var spike:=CylinderMesh.new();spike.top_radius=0;spike.bottom_radius=0.055;spike.height=0.17;spike.radial_segments=5
   BakeryVisuals.shape(hat,Vector3(cos(angle)*0.21,0.47,sin(angle)*0.21),spike,style.trim)
  for side in [-1,1]:BakeryVisuals.box(body,Vector3(side*0.12,0.63,-0.27),Vector3(0.035,0.4,0.03),style.trim)
 else:
  BakeryVisuals.cylinder(body,Vector3(0,0.63,0),0.32,0.48,style.primary)
  BakeryVisuals.cylinder(body,Vector3(0,0.94,0),0.285,0.1,style.accent)
  BakeryVisuals.box(body,Vector3(0.12,0.76,-0.32),Vector3(0.13,0.35,0.05),style.accent)
  var beret:=BakeryVisuals.ball(hat,Vector3(0,0.33,0),0.34,style.secondary);beret.scale=Vector3(1,0.4,1)
  BakeryVisuals.ball(hat,Vector3(0.06,0.48,0),0.07,style.trim)
 return true
