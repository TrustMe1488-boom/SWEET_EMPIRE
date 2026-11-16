extends SceneTree
var passed: int = 0
var failed: int = 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("PERSISTENCE ","PASS: " if ok else "FAIL: ",title)
func _initialize(): run.call_deferred()
func run():
 var store := SaveStore.new()
 store.directory = "res://.local/persistence-restart"
 var saved := store.load_data()
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game); await process_frame
 game.process_mode = Node.PROCESS_MODE_DISABLED
 if saved.is_empty():
  game.progression.tutorial.step = 10
  game.economy.grant_reward("restart-fixture",2000)
  check(game.development.buy(&"COFFEE") and game.personnel.hire(&"COFFEE"),"Create upgraded bakery with authored buy/hire operations")
  game.progression.tray_upgrades.upgrade()
  game.spawn_customer()
  game.pedestrians.request_pedestrian()
  game.checkout.add(3)
  saved = GamePersistence.capture(game)
  check(store.write_data(saved),"Persist world for a separate Godot process")
 else:
  check(true,"Read existing world created by previous Godot process")
 check(GamePersistence.restore(saved,game),"Restore expanded world with customers, pedestrian and equipment")
 check(game.capture_rush_state() == saved.world,"Exact world snapshot roundtrip")
 check(game.progression.get_save_data() == saved.progression,"Campaign, rewards and quest ledgers preserved")
 var before := game.progression.crystals.balance
 game.progression.refresh()
 check(game.progression.crystals.balance == before,"Refresh after loading cannot reissue claimed rewards")
 game.queue_free(); await process_frame
 print("PERSISTENCE_RESTART_RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed==0 else 1)
