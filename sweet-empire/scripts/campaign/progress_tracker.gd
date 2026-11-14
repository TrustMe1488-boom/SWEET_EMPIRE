class_name ProgressTracker
extends RefCounted
signal changed
var data: Dictionary = {"deliveries": 0, "served": 0, "sales_income": 0, "left": 0, "streak": 0, "best_streak": 0, "movement": 0.0, "rating": 4.0, "max_rating": 4.0, "tray_level": 1, "upgrades": 0, "rush_success": false, "produced": {}, "picked": {}, "delivered": {}, "sold": {}, "owned": {"COOKIE": true}, "hired": {"COOKIE": true}, "menus": {}, "near": {}}
func amount(metric: String, id: String = "") -> float:
 if id.is_empty(): return float(data.get(metric, 0))
 return float(data.get(metric, {}).get(id, 0))
func _add_product(metric: String, id: String, amount: int):
 data[metric][id] = int(data[metric].get(id, 0)) + amount
func receive(kind: StringName, event: Dictionary):
 match kind:
  &"ProductProduced": _add_product("produced", str(event.product), int(event.amount))
  &"ProductPickedUp": _add_product("picked", str(event.product), int(event.amount))
  &"ProductDelivered":
   var total: int = 0
   for id in event.items:
    var count := int(event.items[id])
    if count > 0:
     _add_product("delivered", str(id), count)
     total += count
   if total > 0: data.deliveries += 1
  &"ProductSold":
   _add_product("sold", str(event.product), 1)
   data.sales_income += int(event.price)
  &"CustomerServed":
   data.served += 1
   data.streak += 1
   data.best_streak = maxi(data.best_streak, data.streak)
  &"CustomerLeft":
   data.left += 1
   data.streak = 0
  &"EquipmentPurchased": data.owned[str(event.product)] = true
  &"ChefHired": data.hired[str(event.product)] = true
  &"StationUpgraded": data.upgrades += 1
  &"TrayUpgraded": data.tray_level = int(event.level)
  &"RatingChanged":
   data.rating = float(event.value)
   data.max_rating = maxf(data.max_rating, data.rating)
  &"MiaMoved": data.movement += float(event.distance)
  &"NearStation": data.near[str(event.station)] = true
  &"MenuOpened": data.menus[str(event.menu)] = true
  &"RushHourCompleted": data.rush_success = true
 changed.emit()
func get_save_data() -> Dictionary:
 return data.duplicate(true)
func load_save_data(value: Dictionary):
 data = value.duplicate(true)
