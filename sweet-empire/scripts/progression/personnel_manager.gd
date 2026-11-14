class_name PersonnelManager
extends RefCounted
signal changed
signal hired(station: ProductionStation)
var development: DevelopmentManager
var economy: EconomySystem
var last_error: String = ""
var _busy: bool = false
var operation_allowed: Callable
func _init(manager: DevelopmentManager, wallet: EconomySystem):
 development = manager
 economy = wallet
func hire_blocker(id: StringName) -> String:
 if operation_allowed.is_valid() and not operation_allowed.call(): return "Завершите обучение или испытание"
 var station := development.get_station(id)
 if station == null: return "Сначала купите оборудование"
 if station.has_cook: return "Повар уже работает"
 if not economy.can_afford(station.product.hire_cost): return "Недостаточно монет"
 return ""
func hire(id: StringName) -> bool:
 if _busy: return false
 last_error = hire_blocker(id)
 if not last_error.is_empty(): return false
 var station := development.get_station(id)
 _busy = true
 if not economy.try_spend(station.product.hire_cost, &"hire", station.product.station_id, "hire:" + str(station.product.id)):
  _busy = false
  return false
 station.has_cook = true
 hired.emit(station)
 development.changed.emit()
 changed.emit()
 _busy = false
 return true
func workplaces() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for product in ProductCatalog.all():
  var station := development.get_station(product.id)
  if station != null: result.append({"product": product, "employed": station.has_cook})
 return result
