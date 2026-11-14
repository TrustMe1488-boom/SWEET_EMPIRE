class_name ProductionStation
extends Node
signal produced(product_id: StringName, amount: int)
# Legacy config remains readable for stage-1 callers; product resources own timings.
var config: ProductionConfig = preload("res://assets/equipment/cookie_production.tres")
var product: ProductDefinition = preload("res://assets/products/cookie.tres")
var inventory := StationInventory.new()
var elapsed: float = 0.0
var has_cook: bool = true
var level: int = 1
func configure(definition: ProductDefinition, staffed: bool = false):
 product = definition
 has_cook = staffed
 inventory.default_product_id = product.id
 inventory.allowed_product_id = product.id
func _ready():
 inventory.capacity = config.capacity
 inventory.default_product_id = product.id
 inventory.allowed_product_id = product.id
func production_time() -> float:
 return product.production_time(level)
func _physics_process(delta: float):
 advance(delta)
func advance(delta: float):
 if not has_cook or delta <= 0 or inventory.space() <= 0: return
 elapsed += delta
 var seconds := production_time()
 while elapsed >= seconds and inventory.space() > 0:
  elapsed -= seconds
  inventory.add(1)
  produced.emit(product.id, 1)
 if inventory.space() == 0: elapsed = 0.0
func increase_level():
 if level >= 5: return
 # Preserve fractional batch progress rather than grant or erase production.
 var fraction := elapsed / production_time()
 level += 1
 elapsed = fraction * production_time()
