class_name CheckoutInventory
extends ItemInventory
const LIMITS = {&"COOKIE":[8,12,16],&"COFFEE":[6,9,12],&"CUPCAKE":[5,7,10],&"CAKE":[3,5,7]}
var level:int=1
func _init():super(-1)
func limit_for(id:StringName)->int:
 return int(LIMITS[id][level-1]) if LIMITS.has(id) else 0
func space_for(id:StringName)->int:
 return maxi(0,limit_for(id)-amount_for(id))
func get_save_data()->Dictionary:
 var data:=super.get_save_data()
 data["checkout_version"]=1
 data["level"]=level
 return data
func load_save_data(data:Dictionary)->bool:
 if not data.get("items") is Dictionary:return false
 var value=data.get("level",1)
 if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)) or int(value)<1 or int(value)>3:return false
 for key in data.items:
  var id:=StringName(str(key))
  var quantity=data.items[key]
  if not LIMITS.has(id) or not (quantity is int or quantity is float) or not is_finite(float(quantity)) or float(quantity)!=floorf(float(quantity)) or float(quantity)<0 or float(quantity)>int(LIMITS[id][int(value)-1]):return false
 # Commit only after every product and level has passed validation.
 level=int(value)
 capacity=-1
 _items.clear()
 for key in data.items:_set_amount(StringName(str(key)),int(data.items[key]))
 changed.emit()
 return true
