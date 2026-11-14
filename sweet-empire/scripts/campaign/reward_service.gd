class_name RewardService
extends RefCounted
signal granted(id: String, title: String, coins: int, crystals: int)
var economy: EconomySystem
var wallet: CrystalWallet
var claimed: Dictionary = {}
func _init(money: EconomySystem, gems: CrystalWallet):
 economy = money
 wallet = gems
func grant(id: String, title: String, coins: int = 0, crystals: int = 0) -> bool:
 if claimed.has(id) or id.is_empty(): return false
 claimed[id] = true
 if coins > 0: economy.grant_reward(id, coins)
 if crystals > 0: wallet.grant_once(id, crystals)
 granted.emit(id, title, coins, crystals)
 return true
func get_save_data() -> Dictionary:
 return claimed.duplicate()
func load_save_data(data: Dictionary):
 claimed = data.duplicate()
