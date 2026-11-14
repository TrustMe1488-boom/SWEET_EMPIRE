class_name GameSessionManager
extends Node
var retiring:Array=[]
var closing:bool=false
var wallet := CrystalWallet.new()
var cosmetics: CosmeticManager
var active_game: Node
var _moving: bool = false
var _resume_paused: bool = false
func _ready():
 process_mode = Node.PROCESS_MODE_ALWAYS
 cosmetics = CosmeticManager.new(wallet)
 cosmetics.spending_limit = spendable_crystals
 cosmetics.purchase_commit = _commit_purchase
 cosmetics.changed.connect(_sync_style)
 _sync_style()
func _sync_style():
 BakeryVisuals.dessert_style = cosmetics.active("DESSERT_STYLE").style
func has_game() -> bool:
 return is_instance_valid(active_game) and not active_game.is_queued_for_deletion()
func bind_game(game: Node):
 active_game = game
 if game.progression != null:
  wallet = game.progression.crystals
  cosmetics.wallet = wallet
func start_or_continue():
 if _moving: return
 _moving = true
 _start_or_continue.call_deferred()
func _start_or_continue():
 var tree := get_tree()
 if has_game() and not active_game.is_inside_tree():
  var menu := tree.current_scene
  if menu != null:
   tree.root.remove_child(menu)
   menu.queue_free()
  tree.root.add_child(active_game)
  tree.current_scene = active_game
  active_game.apply_cosmetics(cosmetics)
  get_node("/root/AudioHub").set_music("rush" if active_game.spawner.rush_mode else "game")
  active_game.camera.current = true
  if active_game.campaign_view != null: active_game.campaign_view.refresh()
  tree.paused = _resume_paused
 else:
  CampaignLaunch.requested = true
  tree.paused = false
  tree.change_scene_to_file("res://scenes/bakery_game.tscn")
 _moving = false
func return_to_menu(game: Node):
 if _moving: return
 _moving = true
 _return_to_menu.call_deferred(game)
func _return_to_menu(game: Node):
 bind_game(game)
 _resume_paused = game.modal_kind == &"victory"
 if not _resume_paused: game.set_paused(false)
 var tree := get_tree()
 if tree.current_scene == game: tree.current_scene = null
 game.get_parent().remove_child(game)
 # Detached nodes retain exact timers, queue, trial checkpoint and UI state,
 # but no process/input/physics callbacks execute, including ALWAYS children.
 tree.paused = false
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 tree.root.add_child(menu)
 tree.current_scene = menu
 _moving = false
func spendable_crystals() -> int:
 if has_game() and active_game.progression != null and active_game.progression.rush.active:
  return int(active_game.progression.rush.checkpoint.progression.crystals.balance)
 return wallet.balance
func _commit_purchase(id: StringName, amount: int) -> bool:
 if has_game() and active_game.progression != null and active_game.progression.rush.active:
  var checkpoint: Dictionary = active_game.progression.rush.checkpoint
  var confirmed := CrystalWallet.new()
  if not confirmed.load_save_data(checkpoint.progression.crystals): return false
  if not confirmed.try_spend_once("cosmetic:" + str(id),amount,false): return false
  checkpoint.progression.crystals = confirmed.get_save_data()
 return true
func get_save_data() -> Dictionary:
 return {"version":1,"wallet":wallet.get_save_data(),"cosmetics":cosmetics.get_save_data()}
func load_save_data(data: Dictionary) -> bool:
 if data.get("version") != 1 or not data.get("wallet") is Dictionary or not data.get("cosmetics") is Dictionary: return false
 var check_wallet := CrystalWallet.new()
 if not check_wallet.load_save_data(data.wallet): return false
 var check_cosmetics := CosmeticManager.new(check_wallet)
 if not check_cosmetics.load_save_data(data.cosmetics): return false
 var debits: Dictionary = check_wallet.get_save_data().spends
 for item in CosmeticCatalog.all():
  if not item.is_free and check_cosmetics.owns(item.id) != (int(debits.get("cosmetic:"+str(item.id),0))==item.price): return false
 for key in debits:
  if str(key).begins_with("cosmetic:"):
   var item:=CosmeticCatalog.find(StringName(str(key).trim_prefix("cosmetic:")))
   if item==null or item.is_free or int(debits[key])!=item.price or not check_cosmetics.owns(item.id): return false
 # A live bakery owns its campaign state; disk-load orchestration belongs to stage6.
 if has_game(): return false
 wallet.load_save_data(data.wallet,false)
 cosmetics.load_save_data(data.cosmetics)
 wallet.changed.emit()
 return true
func _exit_tree():
 closing=true
 for row in retiring:
  if OS.is_process_running(row.pid):OS.kill(row.pid)
 if has_game() and active_game.get_parent()==null: active_game.free()

func retire_process(pid:int):
 if closing:
  if OS.is_process_running(pid):OS.kill(pid)
 else:retiring.append({"pid":pid,"deadline":Time.get_ticks_msec()+750})
func _process(_delta:float):
 for row in retiring.duplicate():
  if not OS.is_process_running(row.pid):retiring.erase(row)
  elif Time.get_ticks_msec()>int(row.deadline):OS.kill(row.pid);retiring.erase(row)
