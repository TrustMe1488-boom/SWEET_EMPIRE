class_name CrystalWallet
extends RefCounted
signal changed
var _claims: Dictionary = {}
var _spends: Dictionary = {}
var balance: int = 0
func grant_once(id: String, amount: int) -> bool:
 if id.is_empty() or amount <= 0 or _claims.has(id): return false
 _claims[id] = amount
 balance += amount
 changed.emit()
 return true
func try_spend_once(id: String, amount: int, notify: bool = true) -> bool:
 if id.is_empty() or amount <= 0 or amount > balance or _spends.has(id): return false
 _spends[id] = amount
 balance -= amount
 if notify: changed.emit()
 return true
func get_save_data() -> Dictionary:
 return {"version":2,"balance":balance,"claims":_claims.duplicate(),"spends":_spends.duplicate()}
func load_save_data(data: Dictionary, notify: bool = true) -> bool:
 var version = data.get("version",0)
 if not (version is int or version is float) or not is_finite(float(version)) or float(version)!=floorf(float(version)): return false
 if int(version) not in [1,2] or not data.get("claims") is Dictionary: return false
 var claims: Dictionary = data.claims
 if not data.get("spends",{}) is Dictionary: return false
 var spends: Dictionary = data.get("spends",{})
 var total: int = 0
 var ledgers := [claims,spends]
 for index in 2:
  var ledger: Dictionary = ledgers[index]
  for key in ledger:
   var value = ledger[key]
   if not key is String or key.is_empty() or not (value is int or value is float) or not is_finite(float(value)) or float(value) <= 0 or float(value) != floorf(float(value)): return false
   total += int(value) if index == 0 else -int(value)
 var saved_balance = data.get("balance",-1)
 if not (saved_balance is int or saved_balance is float) or not is_finite(float(saved_balance)) or float(saved_balance) != total or total < 0: return false
 _claims = claims.duplicate()
 _spends = spends.duplicate()
 balance = total
 if notify: changed.emit()
 return true

func total_earned() -> int:
 var total:int=0
 for amount in _claims.values():total+=int(amount)
 return total
func total_spent() -> int:
 var total:int=0
 for amount in _spends.values():total+=int(amount)
 return total
