class_name ItemInventory
extends RefCounted
signal changed
var capacity: int
var default_product_id: StringName = &"COOKIE"
var allowed_product_id: StringName = &""
var _items: Dictionary = {}
var count: int:
 get:
  var total: int = 0
  for amount in _items.values(): total += amount
  return total
func _init(limit: int = -1):
 capacity = limit
func contents() -> Dictionary:
 return _items.duplicate()
func amount_for(id: StringName) -> int:
 return _items.get(id, 0)
func accepts(id: StringName) -> bool:
 var definition := ProductCatalog.find(id)
 return definition != null and definition.id == id and (allowed_product_id == &"" or allowed_product_id == id)
func space() -> int:
 return 2147483647 if capacity < 0 else maxi(0, capacity - count)
func space_for(_id: StringName) -> int:
 return space()
func add(amount: int, product_id: StringName = &"") -> int:
 var id := default_product_id if product_id == &"" else product_id
 if not accepts(id): return 0
 var moved := mini(maxi(amount, 0), space_for(id))
 if moved > 0:
  _items[id] = amount_for(id) + moved
  changed.emit()
 return moved
func take(amount: int, product_id: StringName = &"") -> int:
 var id := default_product_id if product_id == &"" else product_id
 var moved := mini(maxi(amount, 0), amount_for(id))
 if moved > 0:
  _set_amount(id, amount_for(id) - moved)
  changed.emit()
 return moved
func _set_amount(id: StringName, amount: int):
 if amount <= 0: _items.erase(id)
 else: _items[id] = amount
func transfer_to(target: ItemInventory, product_id: StringName = &"") -> int:
 if target == self: return 0
 var moved: int = 0
 # Commit every product in both inventories before either observer runs.
 for product in ProductCatalog.all():
  var id := product.id
  if product_id != &"" and id != product_id: continue
  if not target.accepts(id): continue
  var quantity := mini(amount_for(id), target.space_for(id))
  if quantity <= 0: continue
  _set_amount(id, amount_for(id) - quantity)
  target._set_amount(id, target.amount_for(id) + quantity)
  moved += quantity
 if moved > 0:
  changed.emit()
  target.changed.emit()
 return moved

func get_save_data() -> Dictionary:
 var items: Dictionary = {}
 for id in _items: items[str(id)] = _items[id]
 return {"capacity":capacity, "items":items}
func load_save_data(data: Dictionary) -> bool:
 if not data.get("items", null) is Dictionary: return false
 var restored: Dictionary = {}
 var total: int = 0
 for id in data.items:
  if not accepts(StringName(id)) or int(data.items[id]) < 0: return false
  restored[StringName(id)] = int(data.items[id])
  total += int(data.items[id])
 var limit := int(data.get("capacity", capacity))
 if limit >= 0 and total > limit: return false
 capacity = limit
 _items = restored
 changed.emit()
 return true
