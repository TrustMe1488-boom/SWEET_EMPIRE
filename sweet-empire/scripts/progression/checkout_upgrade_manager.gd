class_name CheckoutUpgradeManager
extends RefCounted
signal changed
signal upgraded(level:int)
const COSTS=[250,700]
var checkout:CheckoutInventory
var economy:EconomySystem
var allowed:Callable
var _busy:bool=false
var level:int:
 get:return checkout.level
func _init(stock:CheckoutInventory,money:EconomySystem):checkout=stock;economy=money
func upgrade(expected_level:int=-1)->bool:
 if _busy or level>=3 or (expected_level!=-1 and expected_level!=level):return false
 if allowed.is_valid() and not allowed.call():return false
 var cost:int=COSTS[level-1]
 if not economy.can_afford(cost):return false
 _busy=true
 if not economy.try_spend(cost,&"checkout_upgrade",&"CHECKOUT","checkout:%d"%level):_busy=false;return false
 checkout.level+=1
 checkout.changed.emit();upgraded.emit(level);changed.emit()
 _busy=false
 return true
func get_save_data()->Dictionary:return {"version":1,"level":level}
func load_save_data(data:Dictionary)->bool:
 if int(data.get("version",0))!=1:return false
 var snapshot:=checkout.get_save_data();snapshot.level=data.get("level",0)
 return checkout.load_save_data(snapshot)
