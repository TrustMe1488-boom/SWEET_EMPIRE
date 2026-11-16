class_name StationIndicator
extends Node3D
var station:ProductionStation
var mia:Node3D
var label:Label3D
func _ready():
 position=station.product.world_position+Vector3(0,2.05,0)
 BakeryVisuals.product(self,Vector3(0,0.2,0),station.product.id)
 label=BakeryVisuals.label(self,Vector3.ZERO,"",18);label.pixel_size=0.006
func _process(_delta:float):
 label.text="%s · %d/%d"%[station.product.display_name,station.inventory.count,station.inventory.capacity]
 if mia.position.distance_to(station.product.world_position)<3.0:
  label.text+="\n"
  if not station.has_cook:label.text+="Нужен повар"
  elif station.inventory.count>=5:label.text+="Готово 5/5"
  else:label.text+="Повар работает · %d%% · %.1f с"%[roundi(station.elapsed/station.production_time()*100),station.production_time()-station.elapsed]
