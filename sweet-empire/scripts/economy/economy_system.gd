class_name EconomySystem
extends RefCounted
signal changed
signal sale_recorded(product_id: StringName, price: int)
var _balance: int = 0
var _history: Array[Dictionary] = []
var _spent_keys: Dictionary = {}
var _reward_keys: Dictionary = {}
var coins: int:
 get: return _balance
var history: Array[Dictionary]:
 get: return _history.duplicate(true)
func can_afford(amount: int) -> bool:
 return amount >= 0 and _balance >= amount
func record_sale(product_id: StringName = &"COOKIE") -> bool:
 var product := ProductCatalog.find(product_id)
 if product == null: return false
 _record(product.sale_price, &"sale", product.id)
 sale_recorded.emit(product.id, product.sale_price)
 return true
func try_spend(amount: int, category: StringName, subject: StringName, key: String) -> bool:
 if key.is_empty() or _spent_keys.has(key) or not can_afford(amount): return false
 _spent_keys[key] = true
 _record(-amount, category, subject)
 return true
func _record(delta: int, category: StringName, subject: StringName):
 _balance += delta
 if category == &"sale": sales_total += delta
 if delta < 0: expenses_total -= delta
 _history.append({"sequence": _history.size() + 1, "category": category, "subject": subject, "amount": delta, "balance": _balance})
 changed.emit()

func grant_reward(id: String, amount: int) -> bool:
 if id.is_empty() or amount <= 0 or _reward_keys.has(id): return false
 _reward_keys[id] = true
 _record(amount, &"reward", StringName(id))
 return true
func get_save_data() -> Dictionary:
 return {"balance":_balance, "history":_history.duplicate(true), "spent":_spent_keys.duplicate(), "rewards":_reward_keys.duplicate()}
func load_save_data(data: Dictionary):
 _balance = maxi(0, int(data.balance))
 _history.assign(data.history.duplicate(true))
 _spent_keys = data.spent.duplicate()
 _reward_keys = data.rewards.duplicate()
 sales_total = 0
 expenses_total = 0
 for row in _history:
  if StringName(row.category) == &"sale": sales_total += int(row.amount)
  if int(row.amount) < 0: expenses_total -= int(row.amount)
 changed.emit()
var sales_total: int = 0
var expenses_total: int = 0
