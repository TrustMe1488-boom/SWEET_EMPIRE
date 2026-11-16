class_name CosmeticVisualApplicator
extends RefCounted
static func base_material(mesh: GeometryInstance3D) -> StandardMaterial3D:
 if not mesh.has_meta("cosmetic_base_material"):
  var material: Material = mesh.material_override
  if material == null:
   if mesh is MeshInstance3D and mesh.mesh != null: material = mesh.mesh.material
   elif mesh is MultiMeshInstance3D and mesh.multimesh != null: material = mesh.multimesh.mesh.material
  if material is StandardMaterial3D: mesh.set_meta("cosmetic_base_material",material)
 return mesh.get_meta("cosmetic_base_material") if mesh.has_meta("cosmetic_base_material") else null
static func apply_outfit(model: ChibiVisual, definition: CosmeticDefinition):
 if model == null or model.body == null: return
 var style := definition.style
 GeometricOutfit.reset(model)
 _outfit_parts(model.body,model,style)
 var details: Node3D = model.body.get_node_or_null("CosmeticDetails")
 if details == null:
  details=Node3D.new();details.name="CosmeticDetails";model.body.add_child(details)
 for child in details.get_children(): details.remove_child(child);child.queue_free()
 if GeometricOutfit.build(model,style,details):return
 if style.detail == "classic": return
 # Clothing details are children of animated pivots; gameplay transforms stay untouched.
 for side in [-1,1]:
  BakeryVisuals.ball(details,Vector3(side*0.075,0.73,-0.254),0.025,style.trim)
  BakeryVisuals.box(details,Vector3(side*0.19,0.47,-0.283),Vector3(0.026,0.18,0.02),style.trim)
 var band: Node3D=model.head.get_node_or_null("CosmeticHatBand")
 if band == null:
  band=Node3D.new();band.name="CosmeticHatBand";model.head.add_child(band)
 for child in band.get_children(): band.remove_child(child);child.queue_free()
 BakeryVisuals.cylinder(band,Vector3(0,0.34,0),0.293,0.047,style.secondary)
 if style.detail=="lavender":
  for i in 5:
   var angle:=i*TAU/5
   BakeryVisuals.ball(band,Vector3(-0.16+cos(angle)*0.038,0.36+sin(angle)*0.038,-0.247),0.028,style.accent)
  BakeryVisuals.ball(band,Vector3(-0.16,0.36,-0.274),0.024,style.trim)
 else:
  for side in [-1,1]:
   var bow:=BakeryVisuals.ball(band,Vector3(side*0.045,0.35,-0.28),0.05,style.accent)
   bow.scale=Vector3(1,0.7,0.4)
static func _outfit_parts(node: Node, model: ChibiVisual, style: CosmeticStyle):
 if node == model.tray or node == model.bag or node.name in ["CosmeticDetails","CosmeticHatBand","GeometricCostume"]: return
 if node is MeshInstance3D:
  var material:=base_material(node)
  if material != null:
   var color:=material.albedo_color
   var target:=color
   if node != model.head and not model.head.is_ancestor_of(node):
    if color.is_equal_approx(model.clothing): target=BakeryVisuals.CREAM if style.detail=="classic" else style.primary
    elif color.is_equal_approx(model.clothing.darkened(0.07)): target=(BakeryVisuals.CREAM if style.detail=="classic" else style.primary).darkened(0.07)
    elif color.is_equal_approx(BakeryVisuals.PINK): target=BakeryVisuals.PINK if style.detail=="classic" else style.secondary
    elif color.is_equal_approx(BakeryVisuals.PINK.darkened(0.12)): target=(BakeryVisuals.PINK if style.detail=="classic" else style.secondary).darkened(0.12)
   elif color.is_equal_approx(BakeryVisuals.PINK): target=BakeryVisuals.PINK if style.detail=="classic" else style.accent
   node.material_override=BakeryVisuals.material(target)
 for child in node.get_children(): _outfit_parts(child,model,style)
 if node==model.head and style.detail=="classic":
  var band:=node.get_node_or_null("CosmeticHatBand")
  if band != null:
   for child in band.get_children():band.remove_child(child);child.queue_free()
static func _theme_color(color: Color, style: CosmeticStyle) -> Color:
 if color.is_equal_approx(BakeryVisuals.PINK):return style.primary
 if color.is_equal_approx(BakeryVisuals.MINT):return style.secondary
 if color.is_equal_approx(BakeryVisuals.LAVENDER):return style.accent
 if color.is_equal_approx(BakeryVisuals.CARAMEL):return style.trim
 if color.is_equal_approx(BakeryVisuals.CREAM):return style.base
 if color.is_equal_approx(Color("#eee0cf")):return style.floor_accent
 if color.is_equal_approx(Color("#65516b")):return style.ink
 return color
static func apply_theme(root: Node, definition: CosmeticDefinition):
 _theme_parts(root,definition.style)
 # Shared themed embellishments are visual only and appear in preview and game.
 if root is BakeryInterior or root is ExpansionZone:
  var visual: Node3D=root.get_node("VisualRoot")
  var decorations: Node3D=visual.get_node_or_null("CosmeticDecor")
  if decorations==null:decorations=Node3D.new();decorations.name="CosmeticDecor";visual.add_child(decorations)
  for child in decorations.get_children():decorations.remove_child(child);child.queue_free()
  if definition.style.detail!="classic":
   var z:float=-5.05 if root is BakeryInterior else -2.07
   for x in [-4.9,4.9]:
    BakeryVisuals.cylinder(decorations,Vector3(x,2.17,z),0.1,0.035,definition.style.trim).rotation_degrees.x=90
    for i in 5:
     var angle:=i*TAU/5
     var petal:=BakeryVisuals.ball(decorations,Vector3(x+cos(angle)*0.14,2.17+sin(angle)*0.14,z+0.025),0.075,definition.style.primary)
     petal.scale.z=0.4
static func _theme_parts(node: Node, style: CosmeticStyle):
 if node is ChibiVisual or node.has_meta("cosmetic_product_id") or node.name=="CosmeticDecor":return
 if node is GeometryInstance3D:
  var material:=base_material(node)
  if material!=null:node.material_override=BakeryVisuals.material(_theme_color(material.albedo_color,style))
 for child in node.get_children():_theme_parts(child,style)
static func refresh_products(root: Node):
 var groups:Dictionary={}
 for child in root.get_children():
  if child.has_meta("cosmetic_product_group"):
   var key:int=child.get_meta("cosmetic_product_group")
   if not groups.has(key):groups[key]={"id":child.get_meta("cosmetic_product_id"),"at":child.get_meta("cosmetic_product_origin"),"nodes":[]}
   groups[key].nodes.append(child)
  else:refresh_products(child)
 for group in groups.values():
  for child in group.nodes:root.remove_child(child);child.queue_free()
  BakeryVisuals.product(root,group.at,group.id)
