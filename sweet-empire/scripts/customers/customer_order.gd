class_name CustomerOrder
extends RefCounted
var _product_id: StringName
var product_id: StringName:
 get: return _product_id
func _init(id: StringName = &"COOKIE"):
 var definition := ProductCatalog.find(id)
 _product_id = definition.id if definition != null else &"COOKIE"
