class_name ProductCatalog
extends RefCounted
static func all() -> Array[ProductDefinition]:
 return [preload("res://assets/products/cookie.tres"), preload("res://assets/products/coffee.tres"), preload("res://assets/products/cupcake.tres"), preload("res://assets/products/cake.tres")]
static func find(id: StringName) -> ProductDefinition:
 for product in all():
  if product.id == id or product.station_id == id: return product
 return null
