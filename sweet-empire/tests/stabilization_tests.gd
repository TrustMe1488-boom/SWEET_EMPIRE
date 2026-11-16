extends SceneTree
var passed: int = 0
var failed: int = 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("STABILIZATION ", "PASS: " if ok else "FAIL: ", title)
func _initialize(): run.call_deferred()
func run():
 var bridge := GestureBridge.new()
 bridge.camera_ready = true
 var notified := {"value":false}
 bridge.status_changed.connect(func(_text):notified.value=true)
 bridge.stop()
 check(not bridge.camera_ready and not bridge.active and bridge.pid==-1 and notified.value,"Stopping inactive camera clears readiness and notifies UI without launching a process")
 bridge.free()
 var session = root.get_node("GameSession")
 var retiring_count: int = session.retiring.size()
 session.retire_process(-1)
 check(session.retiring.size()==retiring_count,"Invalid process ID is never scheduled for termination")
 var money := EconomySystem.new()
 var wallet := CrystalWallet.new()
 var campaign := CampaignManager.new(RewardService.new(money, wallet))
 var before := campaign.get_save_data()
 var bad := before.duplicate(true); bad.stage = 2
 check(not campaign.load_save_data(bad) and campaign.get_save_data() == before, "Reject skipped campaign chapter without mutation")
 bad = before.duplicate(true); bad.stage = 1.5
 check(not campaign.load_save_data(bad), "Reject fractional campaign stage")
 var store := SaveStore.new()
 store.directory = "res://.local/save-tests/" + str(Time.get_ticks_usec())
 check(store.load_data().is_empty(), "Missing save is handled")
 var first := {"version":1,"rng":9223372036854775806,"position":Vector3(1,2,3),"nested":{"claimed":true}}
 check(store.write_data(first), "Write verified save")
 check(store.load_data() == first, "Roundtrip typed world values and int64 RNG")
 var second := first.duplicate(true); second.rng = 123
 check(store.write_data(second) and store.load_data() == second, "Replace save atomically")
 var file := FileAccess.open(store.directory.path_join("save.dat"), FileAccess.WRITE)
 file.store_string("truncated"); file.close()
 check(store.load_data() == first, "Corrupt primary restores previous verified state")
 store.validate_payload = func(value): return value.get("version") == 1
 check(store.write_data(second),"Write with semantic validator")
 var unvalidated := SaveStore.new(); unvalidated.directory = store.directory
 check(unvalidated.write_data({"version":999}),"Create structurally readable but incompatible fixture")
 check(store.load_data()==second,"Semantic corruption falls back to previous valid payload")
 check(store.write_data(first) and store.load_data()==first,"Recovery preserves corrupt payload before writing a valid save")
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game); await process_frame
 var snapshot := game.progression.get_save_data()
 var disk := GamePersistence.capture(game)
 check(GamePersistence.validate(disk,game), "Fresh world snapshot validates")
 var candidate: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 candidate.campaign_enabled = true
 root.add_child(candidate); await process_frame
 check(GamePersistence.restore(disk,candidate), "Restore campaign and world into fresh instance")
 check(candidate.progression.get_save_data() == snapshot, "Restore preserves progression and reward ledgers")
 candidate.queue_free(); await process_frame
 bad = snapshot.duplicate(true); bad.events.seen = "invalid"
 check(not game.progression.load_save_data(bad) and game.progression.get_save_data() == snapshot, "Bad late event data cannot partially mutate campaign")
 bad = snapshot.duplicate(true); bad.repeatable.records = "invalid"
 check(not game.progression.load_save_data(bad) and game.progression.get_save_data() == snapshot, "Bad repeatable data rejected before campaign mutation")
 bad = snapshot.duplicate(true); bad.quests.records.q1_cookies.progress = {}
 check(not game.progression.load_save_data(bad) and game.progression.get_save_data() == snapshot,"Malformed nested quest rejected atomically without script error")
 var started: int = Time.get_ticks_usec()
 for i in 12000: game.demand.record("PotentialDemand",{"product":"COOKIE"})
 check(game.demand.records.size()==DemandDataCollector.MAX_RECORDS,"Analytics retained events remain bounded after 12000 events")
 var features := game.demand.features()
 check(features.size()==DemandPredictor.FEATURES.size(),"Bounded history preserves ML feature schema")
 print("ANALYTICS_PROBE_US: ",Time.get_ticks_usec()-started)
 game.process_mode = Node.PROCESS_MODE_DISABLED
 game.progression.tutorial.step = 10
 game.economy.grant_reward("rush-save-fixture",10000)
 game.development.buy(&"COFFEE"); game.personnel.hire(&"COFFEE")
 game.development.buy(&"CUPCAKE"); game.personnel.hire(&"CUPCAKE")
 game.zones.unlock_zone3_for_campaign(true)
 game.development.buy(&"CAKE"); game.personnel.hire(&"CAKE")
 game.progression.campaign.stage = 3
 game.progression.campaign.completed = {"small_beginning":true,"growing_bakery":true}
 game.progression.stats.data.served = 100
 game.progression.stats.data.rating = 4.5
 game.progression.crystals.grant_once("rush-save-fixture",100)
 check(game.progression.rush.start(true),"Create active Rush save fixture with equipment")
 var rush_save := GamePersistence.capture(game)
 var original_profile: Dictionary = session.get_save_data()
 var pending_wardrobe := CosmeticManager.new(game.progression.crystals)
 check(session.load_save_data({"version":1,"wallet":game.progression.crystals.get_save_data(),"cosmetics":pending_wardrobe.get_save_data()}),"Prepare profile for pending-world shop fixture")
 session.pending_game = rush_save.duplicate(true)
 var confirmed_before: int = session.wallet.balance
 check(session.cosmetics.purchase(&"MIA_MINT") and session.wallet.balance==confirmed_before-20 and session.pending_game.progression.crystals==session.wallet.get_save_data() and session.pending_game.rush.checkpoint.progression.crystals.balance==confirmed_before-20,"Purchase before Continue updates pending Rush wallet and permanent checkpoint atomically")
 session.wallet.grant_once("provisional-fixture",100)
 check(session.cosmetics.purchase(&"INTERIOR_GOLD") and not session.cosmetics.purchase(&"MIA_LAVENDER"),"Pending Rush cannot spend provisional crystals beyond confirmed balance")
 session.pending_game.clear()
 check(session.load_save_data(original_profile),"Restore isolated profile after shop fixture")
 check(GamePersistence.validate(rush_save),"Validate active Rush and nested checkpoint without creating BakeryGame")
 var resumed: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 resumed.campaign_enabled = true; resumed.process_mode = Node.PROCESS_MODE_DISABLED
 root.add_child(resumed); await process_frame
 check(GamePersistence.restore(rush_save,resumed) and resumed.progression.rush.active and resumed.progression.rush.checkpoint==rush_save.rush.checkpoint,"Restore active Rush with exact checkpoint")
 resumed.queue_free(); await process_frame
 game.progression.rush.active = false
 game.progression.rush.won = true
 game.spawner.rush_mode = false
 game.progression.campaign.won = true
 game.progression.campaign.endless = true
 game.progression.campaign.completed.sweet_empire = true
 game.progression.stats.data.rush_success = true
 game.progression.refresh()
 var endless_save := GamePersistence.capture(game)
 var endless: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 endless.campaign_enabled = true; endless.process_mode = Node.PROCESS_MODE_DISABLED
 root.add_child(endless); await process_frame
 check(GamePersistence.restore(endless_save,endless) and endless.progression.campaign.endless and endless.progression.repeatable.get_save_data()==endless_save.progression.repeatable,"Restore Endless and repeatable quest deduplication")
 endless.queue_free(); await process_frame
 var wardrobe := CosmeticManager.new(game.progression.crystals)
 var payload := {"version":1,"profile":{"version":1,"wallet":game.progression.crystals.get_save_data(),"cosmetics":wardrobe.get_save_data()},"game":GamePersistence.capture(game),"settings":{}}
 var volume_store := SaveStore.new()
 volume_store.directory = "res://.local/save-volume/" + str(Time.get_ticks_usec())
 volume_store.validate_payload = session.validate_snapshot
 var save_started: int = Time.get_ticks_usec()
 check(volume_store.write_data(payload) and volume_store.load_data()==payload,"Full-size telemetry snapshot validates and roundtrips through production save schema")
 print("SAVE_PROBE_BYTES: ",var_to_bytes(payload).size())
 print("SAVE_PROBE_US: ",Time.get_ticks_usec()-save_started)
 game.queue_free(); await process_frame
 print("STABILIZATION_RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed == 0 else 1)
