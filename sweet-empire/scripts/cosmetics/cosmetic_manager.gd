class_name CosmeticManager
extends RefCounted
signal changed
signal cosmetic_purchased(id: StringName)
signal cosmetic_equipped(id: StringName)
enum Status { LOCKED, OWNED, EQUIPPED }
var wallet: CrystalWallet
var _owned: Dictionary = {}
var _active: Dictionary = {}
var _busy: bool = false
var last_error: String = ""
var spending_limit: Callable
var purchase_commit: Callable
func _init(crystals: CrystalWallet):
 wallet = crystals
 for item in CosmeticCatalog.all():
  if item.is_free:
   _owned[item.id] = true
   if not _active.has(item.category): _active[item.category] = item.id
func owns(id: StringName) -> bool: return _owned.has(id)
func active(category: String) -> CosmeticDefinition: return CosmeticCatalog.find(_active.get(category,&""))
func status(id: StringName) -> Status:
 var item := CosmeticCatalog.find(id)
 if item == null or not owns(id): return Status.LOCKED
 return Status.EQUIPPED if _active.get(item.category) == id else Status.OWNED
func available_balance() -> int:
 return mini(wallet.balance, int(spending_limit.call())) if spending_limit.is_valid() else wallet.balance
func purchase_blocker(id: StringName) -> String:
 var item := CosmeticCatalog.find(id)
 if item == null: return "Предмет не найден."
 if owns(id): return "Предмет уже приобретён."
 if item.price < 0: return "Некорректная цена."
 if available_balance() < item.price:
  return "Во время Rush Hour доступны только кристаллы до начала попытки." if wallet.balance >= item.price else "Недостаточно кристаллов."
 return ""
func purchase(id: StringName) -> bool:
 if _busy: return false
 last_error = purchase_blocker(id)
 if not last_error.is_empty(): return false
 var item := CosmeticCatalog.find(id)
 _busy = true
 var previous := wallet.get_save_data()
 if not wallet.try_spend_once("cosmetic:" + str(id), item.price, false):
  _busy = false
  last_error = "Оплата не выполнена."
  return false
 _owned[id] = true
 if purchase_commit.is_valid() and not bool(purchase_commit.call(id,item.price)):
  _owned.erase(id)
  wallet.load_save_data(previous,false)
  _busy = false
  last_error = "Не удалось завершить покупку."
  return false
 # Both ownership and debit are committed before observers see a notification.
 wallet.changed.emit()
 cosmetic_purchased.emit(id)
 changed.emit()
 _busy = false
 return true
func equip(id: StringName) -> bool:
 if _busy or not owns(id): return false
 var item := CosmeticCatalog.find(id)
 if item == null: return false
 if _active.get(item.category) == id: return true
 _active[item.category] = id
 cosmetic_equipped.emit(id)
 changed.emit()
 return true
func get_save_data() -> Dictionary:
 var owned: Array[String] = []
 for item in CosmeticCatalog.all():
  if owns(item.id): owned.append(str(item.id))
 var equipped: Dictionary = {}
 for category in CosmeticCatalog.CATEGORIES: equipped[category] = str(_active[category])
 return {"version":1,"owned":owned,"active":equipped}
func load_save_data(data: Dictionary) -> bool:
 if _busy: return false
 if data.get("version") != 1 or not data.get("owned") is Array or not data.get("active") is Dictionary: return false
 var owned: Dictionary = {}
 for value in data.owned:
  if not value is String or CosmeticCatalog.find(StringName(value)) == null or owned.has(StringName(value)): return false
  owned[StringName(value)] = true
 for item in CosmeticCatalog.all():
  if item.is_free: owned[item.id] = true
 if data.active.size() != CosmeticCatalog.CATEGORIES.size(): return false
 var equipped: Dictionary = {}
 for category in CosmeticCatalog.CATEGORIES:
  var id := StringName(str(data.active.get(category,"")))
  var item := CosmeticCatalog.find(id)
  if item == null or item.category != category or not owned.has(id): return false
  equipped[category] = id
 _owned = owned
 _active = equipped
 changed.emit()
 return true
