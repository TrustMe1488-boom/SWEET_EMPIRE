class_name GameSessionManager
extends Node
var retiring:Array=[]
var closing:bool=false
var wallet := CrystalWallet.new()
var cosmetics: CosmeticManager
var active_game: Node
var _moving: bool = false
var _resume_paused: bool = false
var save_store := SaveStore.new()
var pending_game: Dictionary = {}
var settings: Dictionary = {}
var save_status: String = ""
var _save_elapsed: float = 0.0
var _resetting: bool = false
func persistence_enabled() -> bool:
 return not Engine.is_editor_hint() and "--script" not in OS.get_cmdline_args() and "--editor" not in OS.get_cmdline_args()
func _ready():
 process_mode = Node.PROCESS_MODE_ALWAYS
 cosmetics = CosmeticManager.new(wallet)
 cosmetics.spending_limit = spendable_crystals
 cosmetics.purchase_commit = _commit_purchase
 cosmetics.changed.connect(_sync_style)
 _sync_style()
 if persistence_enabled():
  get_tree().auto_accept_quit = false
  save_store.validate_payload = validate_snapshot
  var saved := save_store.load_data()
  if saved.is_empty() and FileAccess.file_exists(save_store.directory.path_join("save.dat")):
   save_status = "Сохранение повреждено или несовместимо; исходный файл сохранён."
  if not saved.is_empty() and saved.get("version") == 1 and saved.get("profile") is Dictionary:
   if load_save_data(saved.profile):
    if saved.get("game") is Dictionary: pending_game = saved.game
    if saved.get("settings") is Dictionary: settings = saved.settings
  load_settings()
  if not settings.is_empty() and not FileAccess.file_exists("user://settings.cfg"): save_settings()
 cosmetics.changed.connect(_save_deferred)
func _save_deferred():
 if persistence_enabled() and not _resetting: save_progress.call_deferred()
func has_continue() -> bool:
 return has_game() or not pending_game.is_empty()
func save_progress() -> bool:
 if not persistence_enabled(): return true
 if not has_game() and pending_game.is_empty(): return false
 var world := pending_game
 if has_game() and active_game.progression != null:
  world = GamePersistence.capture(active_game)
 var success := save_store.write_data({"version":1,"profile":get_save_data(),"game":world,"settings":{}})
 save_status = "Прогресс сохранён" if success else "Не удалось сохранить: " + save_store.last_error
 return success
func load_settings():
 var config := ConfigFile.new()
 if config.load("user://settings.cfg") != OK: return
 var audio = config.get_value("audio","gains",{})
 if audio is Dictionary: settings["audio"] = audio
 var master = config.get_value("audio","master",1.0)
 if master is float or master is int:
  if is_finite(float(master)): settings["master"] = clampf(float(master),0,1)
 var mode = config.get_value("display","fullscreen",false)
 if mode is bool: settings["fullscreen"] = mode
 var resolution = config.get_value("display","resolution",Vector2i(1280,720))
 if resolution is Vector2i and resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]: settings["resolution"] = resolution
 for key in ["sensitivity","deadzone"]:
  if not config.has_section_key("controls",key): continue
  var value = config.get_value("controls",key)
  if value is float and is_finite(value): settings[key]=value
 apply_display_settings()
func apply_display_settings():
 if DisplayServer.get_name()=="headless": return
 var fullscreen: bool = settings.get("fullscreen",false)
 DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
 if not fullscreen: DisplayServer.window_set_size(settings.get("resolution",Vector2i(1280,720)))
func save_settings() -> bool:
 if not persistence_enabled(): return true
 var audio := get_node_or_null("/root/AudioHub")
 if audio != null and audio.is_node_ready(): settings["audio"] = audio.gains.duplicate()
 var config := ConfigFile.new()
 config.set_value("audio","gains",settings.get("audio",{}))
 config.set_value("audio","master",settings.get("master",1.0))
 config.set_value("display","fullscreen",settings.get("fullscreen",false))
 config.set_value("display","resolution",settings.get("resolution",Vector2i(1280,720)))
 for key in ["sensitivity","deadzone"]:
  if settings.has(key): config.set_value("controls",key,settings[key])
 var error := config.save("user://settings.cfg")
 if error != OK: save_status = "Не удалось сохранить настройки"
 return error == OK
func new_game() -> bool:
 if _moving: return false
 # Preserve the current save, including invalid files, before replacing anything.
 var path := save_store.directory.path_join("save.dat")
 if has_game() and not save_progress(): return false
 for source in [path,save_store.directory.path_join("save.previous")]:
  if FileAccess.file_exists(source):
   var archive := save_store.directory.path_join("save.before-new-%d-%d-%s.dat" % [Time.get_unix_time_from_system(),Time.get_ticks_usec(),source.get_file()])
   if DirAccess.copy_absolute(source,archive) != OK: save_status="Не удалось сохранить копию прежнего прогресса"; return false
 _resetting = true
 if has_game():
  var old := active_game
  active_game = null
  if old.get_parent() != null: old.get_parent().remove_child(old)
  old.queue_free()
 pending_game.clear()
 var fresh_wallet := CrystalWallet.new()
 var fresh_cosmetics := CosmeticManager.new(fresh_wallet)
 wallet.load_save_data(fresh_wallet.get_save_data(),false)
 cosmetics.load_save_data(fresh_cosmetics.get_save_data())
 _resume_paused = false
 _resetting = false
 start_or_continue()
 return true
func save_new_game_when_ready(game: BakeryGame):
 if persistence_enabled() and game.session_owned: save_progress.call_deferred()
func restore_pending(game: BakeryGame) -> bool:
 if pending_game.is_empty(): return true
 if not pending_game.get("progression") is Dictionary or pending_game.progression.get("crystals") != wallet.get_save_data():
  save_status = "Сохранение кошелька не соответствует кампании."
  return false
 if not GamePersistence.restore(pending_game,game):
  save_status = "Сохранение несовместимо. Исходный файл сохранён."
  return false
 pending_game.clear()
 bind_game(game)
 game.apply_cosmetics(cosmetics)
 get_node("/root/AudioHub").set_music("rush" if game.progression.rush.active else "game")
 if game.progression.campaign.won and not game.progression.campaign.endless: game.show_victory()
 return true
func _notification(what: int):
 if what == NOTIFICATION_WM_CLOSE_REQUEST and persistence_enabled():
  get_node("/root/AudioHub").quit_game()
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
 save_progress()
 save_settings()
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
 if not pending_game.is_empty() and pending_game.rush.active:
  return int(pending_game.rush.checkpoint.progression.crystals.balance)
 return wallet.balance
func _commit_purchase(id: StringName, amount: int) -> bool:
 if has_game() and active_game.progression != null and active_game.progression.rush.active:
  var checkpoint: Dictionary = active_game.progression.rush.checkpoint
  var confirmed := CrystalWallet.new()
  if not confirmed.load_save_data(checkpoint.progression.crystals): return false
  if not confirmed.try_spend_once("cosmetic:" + str(id),amount,false): return false
  checkpoint.progression.crystals = confirmed.get_save_data()
 elif not pending_game.is_empty():
  if pending_game.rush.active:
   var confirmed := CrystalWallet.new()
   if not confirmed.load_save_data(pending_game.rush.checkpoint.progression.crystals): return false
   if not confirmed.try_spend_once("cosmetic:"+str(id),amount,false): return false
   pending_game.rush.checkpoint.progression.crystals = confirmed.get_save_data()
  pending_game.progression.crystals = wallet.get_save_data()
 return true
func get_save_data() -> Dictionary:
 return {"version":1,"wallet":wallet.get_save_data(),"cosmetics":cosmetics.get_save_data()}
func validate_profile(data: Dictionary) -> bool:
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
 return true
func validate_snapshot(data: Dictionary) -> bool:
 if data.get("version") != 1 or not data.get("profile") is Dictionary or not data.get("game") is Dictionary or not data.get("settings") is Dictionary: return false
 if not validate_profile(data.profile): return false
 if data.settings.has("audio"):
  if not data.settings.audio is Dictionary: return false
  for key in data.settings.audio:
   var value = data.settings.audio[key]
   if key not in ["Music","SFX","UI","Ambient"] or not (value is int or value is float): return false
   if not is_finite(float(value)) or float(value)<0 or float(value)>1: return false
 for key in ["sensitivity","deadzone"]:
  if data.settings.has(key):
   var value = data.settings[key]
   if not (value is int or value is float) or not is_finite(float(value)): return false
 if not data.game.is_empty():
  if not GamePersistence.validate(data.game): return false
  if data.game.progression.crystals != data.profile.wallet: return false
 return true
func load_save_data(data: Dictionary) -> bool:
 if not validate_profile(data): return false
 # A live bakery owns its campaign state; profile loading cannot replace it.
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
 if pid<=0:return
 for row in retiring:
  if row.pid==pid:return
 if closing:
  if OS.is_process_running(pid):OS.kill(pid)
 else:retiring.append({"pid":pid,"deadline":Time.get_ticks_msec()+750})
func _process(_delta:float):
 if persistence_enabled() and not closing:
  _save_elapsed += _delta
  if _save_elapsed >= 60.0:
   _save_elapsed = 0.0
   save_progress()
 for row in retiring.duplicate():
  if not OS.is_process_running(row.pid):retiring.erase(row)
  elif Time.get_ticks_msec()>int(row.deadline):OS.kill(row.pid);retiring.erase(row)
