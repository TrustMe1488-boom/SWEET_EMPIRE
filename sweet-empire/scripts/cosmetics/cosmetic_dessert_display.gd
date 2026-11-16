extends Node3D
var style: CosmeticStyle
func _ready():
 for i in 4:
  var pedestal:=Node3D.new()
  add_child(pedestal)
  pedestal.position=Vector3((i%2-0.5)*1.5,0,(floori(i/2.0)-0.5)*1.3)
  BakeryVisuals.cylinder(pedestal,Vector3(0,-0.08,0),0.59,0.15,BakeryVisuals.CREAM)
  BakeryVisuals.cylinder(pedestal,Vector3(0,0,0),0.56,0.025,BakeryVisuals.LAVENDER)
  var item:=Node3D.new()
  pedestal.add_child(item)
  item.scale=Vector3.ONE*2.6
  BakeryVisuals.product(item,Vector3(0,0.02,0),ProductCatalog.all()[i].id,style)
