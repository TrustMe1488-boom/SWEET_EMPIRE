class_name CosmeticCatalog
extends RefCounted
const CATEGORIES = ["MIA_OUTFIT","INTERIOR_THEME","DESSERT_STYLE"]
static var data: CosmeticCatalogData
static func all() -> Array[CosmeticDefinition]:
 if data == null: data = load("res://assets/cosmetics/catalog.tres")
 return data.items.duplicate()
static func find(id: StringName) -> CosmeticDefinition:
 for item in all():
  if item.id == id: return item
 return null
static func in_category(category: String) -> Array[CosmeticDefinition]:
 var result: Array[CosmeticDefinition] = []
 for item in all():
  if item.category == category: result.append(item)
 return result
static func validate() -> PackedStringArray:
 var errors := PackedStringArray()
 var ids: Dictionary = {}
 var defaults: Dictionary = {}
 for item in all():
  if item.id == &"" or ids.has(item.id): errors.append("Duplicate or empty cosmetic ID: " + str(item.id))
  ids[item.id] = true
  if item.category not in CATEGORIES: errors.append("Unknown category: " + item.category)
  if item.price < 0 or item.is_free != (item.price == 0): errors.append("Invalid price: " + str(item.id))
  if item.style == null or item.visual_scene == null: errors.append("Missing visuals: " + str(item.id))
  if item.preview_camera_size <= 0: errors.append("Invalid preview camera: " + str(item.id))
  if item.is_free: defaults[item.category] = true
 for category in CATEGORIES:
  if not defaults.has(category): errors.append("Missing free default: " + category)
 return errors
