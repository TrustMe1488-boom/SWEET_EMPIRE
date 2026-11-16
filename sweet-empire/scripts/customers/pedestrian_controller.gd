class_name PedestrianController
extends Node3D
var flow:Node
var visitor_id:int=0
var desired_product:StringName=&"COOKIE"
var customer_type:String="NORMAL"
var route:Array[Vector3]=[]
var waypoint:int=0
var decided:bool=false
var appearance:Dictionary={}
var visual:ChibiVisual
func advance(delta:float):
 var remaining:float=maxf(0,delta)*2.2
 while remaining>0 and waypoint<route.size():
  var difference:Vector3=route[waypoint]-position
  var distance:float=difference.length()
  if visual!=null and distance>0.001:visual.rotation.y=atan2(-difference.x,-difference.z)
  if distance>remaining:position+=difference.normalized()*remaining;remaining=0
  else:
   position=route[waypoint];remaining-=distance;waypoint+=1
   if waypoint==1 and not decided:
    decided=true;flow.decide(self)
   if waypoint>=route.size():flow.arrived(self);return
 if visual!=null:visual.set_state(&"Walk")
func get_save_data()->Dictionary:
 return {"id":visitor_id,"desired":str(desired_product),"type":customer_type,"route":route.duplicate(),"waypoint":waypoint,"position":position,"decided":decided,"appearance":appearance.duplicate()}
