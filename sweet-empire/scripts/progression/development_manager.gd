class_name DevelopmentManager
extends Node
signal changed
signal station_upgraded(station: ProductionStation)
signal station_purchased(station: ProductionStation)
var economy: EconomySystem
var zones: ZoneManager
var stations: Dictionary = {}
var last_error: String = ""
var _busy: bool = false
var operation_allowed: Callable
func configure(wallet: EconomySystem, areas: ZoneManager):
 economy = wallet
 zones = areas
 var cookie := ProductionStation.new()
 cookie.configure(ProductCatalog.find(&"COOKIE"), true)
 stations[&"COOKIE"] = cookie
 add_child(cookie)
func get_station(id: StringName) -> ProductionStation:
 var product := ProductCatalog.find(id)
 return null if product == null else stations.get(product.id)
func purchase_blocker(id: StringName) -> String:
 if operation_allowed.is_valid() and not operation_allowed.call(): return "Софи: завершите обучение или испытание"
 var product := ProductCatalog.find(id)
 if product == null: return "Неизвестная станция"
 if get_station(product.id) != null: return "Уже куплено"
 if product.zone == 3 and not zones.is_open(3): return "Зона 3 пока закрыта"
 if product.id == &"CUPCAKE" and not zones.is_open(2): return "Сначала купите кофемашину"
 if not economy.can_afford(product.purchase_cost): return "Недостаточно монет"
 return ""
func buy(id: StringName) -> bool:
 if _busy: return false
 last_error = purchase_blocker(id)
 if not last_error.is_empty(): return false
 var product := ProductCatalog.find(id)
 _busy = true
 if not economy.try_spend(product.purchase_cost, &"equipment", product.station_id, "buy:" + str(product.id)):
  _busy = false
  last_error = "Покупка уже обработана"
  return false
 var station := ProductionStation.new()
 station.configure(product, false)
 stations[product.id] = station
 add_child(station)
 if product.id == &"COFFEE": zones.open_zone2()
 station_purchased.emit(station)
 changed.emit()
 _busy = false
 return true
func upgrade(id: StringName, expected_level: int = -1) -> bool:
 if _busy: return false
 if operation_allowed.is_valid() and not operation_allowed.call():
  last_error = "Софи: завершите обучение или испытание"
  return false
 var station := get_station(id)
 if station == null:
  last_error = "Сначала купите станцию"
  return false
 if station.level >= 5:
  last_error = "Максимальный уровень"
  return false
 if expected_level != -1 and station.level != expected_level:
  last_error = "Улучшение уже обработано"
  return false
 var cost := station.product.upgrade_cost(station.level)
 if not economy.can_afford(cost):
  last_error = "Недостаточно монет"
  return false
 _busy = true
 var key := "upgrade:%s:%d" % [station.product.id, station.level]
 if not economy.try_spend(cost, &"upgrade", station.product.station_id, key):
  _busy = false
  return false
 station.increase_level()
 station_upgraded.emit(station)
 last_error = ""
 changed.emit()
 _busy = false
 return true
func orderable_products() -> Array[ProductDefinition]:
 var result: Array[ProductDefinition] = []
 for product in ProductCatalog.all():
  var station := get_station(product.id)
  if station != null and station.has_cook: result.append(product)
 return result
