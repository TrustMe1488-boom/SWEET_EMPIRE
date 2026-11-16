class_name TrayUpgradeManager
extends RefCounted
signal upgraded(level: int)
signal changed
const CAPACITIES = [5, 8, 12]
const COSTS = [150, 400]
var level: int = 1
var tray: TrayInventory
var economy: EconomySystem
var allowed: Callable
var last_error: String = ""
var _busy: bool = false
func _init(items: TrayInventory, money: EconomySystem):
 tray = items
 economy = money
func upgrade(expected_level: int = -1) -> bool:
 if _busy or level >= 3 or (expected_level != -1 and expected_level != level): return false
 if allowed.is_valid() and not allowed.call():
  last_error = "Завершите текущую часть обучения или испытание"
  return false
 var cost: int = COSTS[level - 1]
 if not economy.can_afford(cost):
  last_error = "Недостаточно монет"
  return false
 _busy = true
 if not economy.try_spend(cost, &"tray_upgrade", &"TRAY", "tray:%d" % level):
  _busy = false
  return false
 level += 1
 tray.capacity = CAPACITIES[level - 1]
 upgraded.emit(level)
 changed.emit()
 tray.changed.emit()
 _busy = false
 return true
func get_save_data() -> Dictionary:
 return {"version": 1, "level": level}
func load_save_data(data: Dictionary) -> bool:
 var raw = data.get("level")
 if not (raw is int or raw is float) or not is_finite(float(raw)) or float(raw)!=floorf(float(raw)): return false
 var value := int(data.get("level", 0))
 if int(data.get("version", 0)) != 1 or value < 1 or value > 3 or CAPACITIES[value - 1] < tray.count: return false
 level = value
 tray.capacity = CAPACITIES[level - 1]
 changed.emit()
 return true
