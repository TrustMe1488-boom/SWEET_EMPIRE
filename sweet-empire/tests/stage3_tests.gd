extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize(): run.call_deferred()
func check(condition: bool, title: String):
 if condition: passed += 1
 else: failed += 1
 print("STAGE3 ", "PASS: " if condition else "FAIL: ", title)
func roundtrip(data: Dictionary) -> Dictionary:
 return JSON.parse_string(JSON.stringify(data))
func run():
 unit_tests()
 await integration_tests()
 print("STAGE3_RESULT: %d passed, %d failed" % [passed, failed])
 quit(0 if failed == 0 else 1)
func unit_tests():
 var money := EconomySystem.new()
 var gems := CrystalWallet.new()
 check(gems.balance == 0 and not gems.grant_once("bad", -1), "Crystal wallet starts empty and rejects negative awards")
 check(gems.grant_once("first", 5) and not gems.grant_once("first", 5) and gems.balance == 5, "Crystal grant is idempotent")
 var clone := CrystalWallet.new()
 check(clone.load_save_data(roundtrip(gems.get_save_data())) and clone.balance == 5 and not clone.grant_once("first", 5), "Crystal JSON roundtrip preserves claims")
 var invalid := gems.get_save_data()
 invalid.balance = 900
 check(not gems.load_save_data(invalid) and gems.balance == 5, "Corrupt crystal balance rejected")
 var rewards := RewardService.new(money, gems)
 check(rewards.grant("test", "Test", 30, 5) and not rewards.grant("test", "Test", 30, 5) and money.coins == 30 and gems.balance == 10, "Mixed reward granted only once")
 var bus := GameEvents.new()
 var stats := ProgressTracker.new()
 bus.occurred.connect(stats.receive)
 check(bus.publish(&"CustomerServed", {}, "same") and not bus.publish(&"CustomerServed", {}, "same") and stats.amount("served") == 1, "Duplicate event token ignored")
 var tutorial := TutorialManager.new()
 stats.data.served = 0
 stats.receive(&"MiaMoved", {"distance":2.0})
 tutorial.evaluate(stats)
 check(tutorial.step == 0, "Welcome requires acknowledgement")
 tutorial.acknowledge()
 tutorial.evaluate(stats)
 check(tutorial.step == 2, "Earlier real movement is remembered")
 stats.receive(&"NearStation", {"station":"oven"})
 tutorial.evaluate(stats)
 check(tutorial.step == 3, "Approach oven step")
 stats.receive(&"ProductPickedUp", {"product":"COOKIE", "amount":1})
 tutorial.evaluate(stats)
 check(tutorial.step == 4, "Pickup step is event based")
 stats.receive(&"NearStation", {"station":"checkout"})
 tutorial.evaluate(stats)
 check(tutorial.step == 5, "Approach checkout step")
 stats.receive(&"ProductDelivered", {"items":{}})
 tutorial.evaluate(stats)
 check(tutorial.step == 5 and stats.amount("deliveries") == 0, "Empty delivery cannot advance tutorial")
 stats.receive(&"ProductDelivered", {"items":{"COOKIE":1}})
 tutorial.evaluate(stats)
 check(tutorial.step == 6, "First delivery counted")
 stats.receive(&"ProductSold", {"product":"COOKIE", "price":10})
 tutorial.evaluate(stats)
 check(tutorial.step == 6, "Income alone is not a served customer")
 stats.receive(&"CustomerServed", {})
 tutorial.evaluate(stats)
 check(tutorial.step == 7, "First successful service advances tutorial")
 for i in 2: stats.receive(&"ProductDelivered", {"items":{"COOKIE":1}})
 tutorial.evaluate(stats)
 check(tutorial.step == 8 and stats.amount("deliveries") == 3, "First three deliveries retained")
 stats.receive(&"MenuOpened", {"menu":"development"})
 tutorial.evaluate(stats)
 check(tutorial.step == 9, "Development menu visited")
 stats.receive(&"MenuOpened", {"menu":"personnel"})
 tutorial.evaluate(stats)
 check(tutorial.done, "Personnel menu completes tutorial")
 var tutorial_clone := TutorialManager.new()
 check(tutorial_clone.load_save_data(roundtrip(tutorial.get_save_data())) and tutorial_clone.done, "Tutorial serialization")
 check(not tutorial_clone.load_save_data({"version":1,"step":99}), "Invalid tutorial step rejected")
 var campaign_money := EconomySystem.new()
 var campaign_gems := CrystalWallet.new()
 var service := RewardService.new(campaign_money, campaign_gems)
 var campaign := CampaignManager.new(service)
 stats.data.deliveries = 5
 stats.data.sales_income = 200
 stats.data.owned.COFFEE = true
 var incomplete := TutorialManager.new()
 campaign.evaluate(stats, incomplete)
 check(campaign.stage == 1 and campaign_gems.balance == 0, "Chapter one requires tutorial")
 campaign.evaluate(stats, tutorial)
 check(campaign.stage == 2 and campaign_gems.balance == 10, "Chapter one reward and transition")
 campaign.evaluate(stats, tutorial)
 check(campaign_gems.balance == 10, "Chapter one cannot reward twice")
 stats.data.hired.COFFEE = true
 stats.data.owned.CUPCAKE = true
 stats.data.tray_level = 2
 stats.data.served = 30
 campaign.evaluate(stats, tutorial)
 check(campaign.stage == 3 and campaign_gems.balance == 30, "Chapter two exact conditions and reward")
 stats.data.owned.CAKE = true
 stats.data.hired.CAKE = true
 stats.data.served = 100
 stats.data.rating = 4.49
 check(not campaign.can_start_rush(stats), "Rush requires current rating at least 4.5")
 stats.data.rating = 4.5
 check(campaign.can_start_rush(stats), "Rush becomes eligible after all preparation goals")
 campaign.evaluate(stats, tutorial)
 check(not campaign.won, "Campaign waits for Rush success")
 stats.data.rush_success = true
 campaign.evaluate(stats, tutorial)
 check(campaign.won and campaign_gems.balance == 80, "Chapter three awards fifty and finishes campaign")
 campaign.evaluate(stats, tutorial)
 check(campaign_gems.balance == 80 and campaign.enter_endless(), "Endless entry cannot duplicate campaign reward")
 stats.data.rating = 1.0
 check(campaign.objectives(stats, tutorial).all(func(goal): return goal.complete), "Finished campaign goals cannot reopen after rating drops in endless mode")
 stats.data.rating = 4.5
 var campaign_clone := CampaignManager.new(service)
 check(campaign_clone.load_save_data(roundtrip(campaign.get_save_data())) and campaign_clone.endless, "Campaign serialization")
 var qm := EconomySystem.new()
 var qg := CrystalWallet.new()
 var qr := RewardService.new(qm, qg)
 var quests := QuestManager.new(qr)
 var qs := ProgressTracker.new()
 qs.data.delivered = {"COOKIE":15, "COFFEE":10}
 qs.data.served = 10
 qs.data.deliveries = 8
 quests.evaluate(qs, 1)
 check(qm.coins == 70 and qg.balance == 5 and not quests.records.q2_coffee.active, "Chapter-one quests activate and reward correct amounts")
 quests.evaluate(qs, 1)
 check(qm.coins == 70 and qg.balance == 5, "Quest rewards are one-shot")
 qs.data.sold.CUPCAKE = 10
 qs.data.upgrades = 1
 quests.evaluate(qs, 2)
 check(qm.coins == 210 and qg.balance == 15 and quests.records.q2_coffee.complete, "Chapter-two quantities include earlier campaign events")
 qs.data.sold.CAKE = 10
 qs.data.deliveries = 20
 qs.data.streak = 90
 quests.evaluate(qs, 3)
 check(qm.coins == 360 and qg.balance == 30 and quests.records.q3_streak.progress == 0, "Stage-three streak starts only at activation")
 for i in 19: quests.note_event(&"CustomerServed", {})
 quests.evaluate(qs, 3)
 check(not quests.records.q3_streak.complete, "Nineteen customers insufficient for streak")
 quests.note_event(&"CustomerLeft", {})
 check(quests.records.q3_streak.progress == 0, "Unserved departure resets active streak")
 for i in 20: quests.note_event(&"CustomerServed", {})
 quests.evaluate(qs, 3)
 check(quests.records.q3_streak.complete and qg.balance == 50, "Twenty consecutive guests grant twenty gems")
 quests.note_event(&"CustomerLeft", {})
 quests.evaluate(qs, 3)
 check(qg.balance == 50, "Completed streak remains awarded once")
 var qc := QuestManager.new(qr)
 check(qc.load_save_data(roundtrip(quests.get_save_data())) and qc.records.q3_streak.complete, "Quest serialization")
 var ag := CrystalWallet.new()
 var ar := RewardService.new(EconomySystem.new(), ag)
 var achievements := AchievementManager.new(ar)
 stats.data.max_rating = 5.0
 stats.data.deliveries = 20
 achievements.evaluate(stats, campaign)
 check(achievements.unlocked.size() == 6 and ag.balance == 65, "All six achievements have exact crystal rewards")
 achievements.evaluate(stats, campaign)
 check(ag.balance == 65, "Achievements cannot be claimed twice")
 var ac := AchievementManager.new(ar)
 check(ac.load_save_data(roundtrip(achievements.get_save_data())) and ac.unlocked.size() == 6, "Achievement serialization")
 var tray := TrayInventory.new()
 var tw := EconomySystem.new()
 tw.grant_reward("seed", 550)
 var upgrades := TrayUpgradeManager.new(tray, tw)
 check(upgrades.level == 1 and tray.capacity == 5, "Initial tray unchanged")
 check(upgrades.upgrade(1) and tw.coins == 400 and tray.capacity == 8, "Tray level two costs 150")
 check(not upgrades.upgrade(1) and tw.coins == 400, "Stale tray purchase cannot charge again")
 tray.add(8, &"COOKIE")
 check(upgrades.upgrade(2) and tw.coins == 0 and tray.capacity == 12 and tray.count == 8, "Tray level three costs 400 and preserves items")
 check(not upgrades.upgrade() and tw.coins == 0, "Tray maximum level enforced")
 check(not upgrades.load_save_data({"version":1,"level":1}) and tray.count == 8 and tray.capacity == 12, "Loading smaller capacity cannot destroy carried items")
 check(upgrades.load_save_data(roundtrip(upgrades.get_save_data())) and upgrades.level == 3, "Tray upgrade serialization")
 var no_funds := TrayUpgradeManager.new(TrayInventory.new(), EconomySystem.new())
 check(not no_funds.upgrade(), "Tray rejects insufficient funds")
func deliver_cookie(game: BakeryGame):
 # Stage5.5 fixture: clear cookie shelf before a new delivery; checkout is now bounded.
 game.checkout.take(game.checkout.amount_for(&"COOKIE"),&"COOKIE")
 game.production.advance(4)
 game.mia.position = game.OVEN_ACCESS
 game._process(0)
 game.interact()
 game.mia.position = game.CHECKOUT_ACCESS
 game._process(0)
 game.interact()
func integration_tests():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game)
 if game.campaign_view == null or game.progression == null:
  check(false, "Campaign scene failed to load")
  return
 await process_frame
 var runtime := game.progression
 check(runtime != null and game.sophie != null and game.campaign_view.dialogue.visible, "Campaign creates Sophie and welcome inside BakeryGame")
 game.campaign_view.dialogue.dismiss()
 check(game.campaign_view.dialogue.requested_visible and runtime.tutorial.step == 0, "Required welcome cannot be dismissed")
 game.economy.grant_reward("qa_funding", 10000)
 check(not game.development.buy(&"COFFEE"), "Equipment purchases locked before tutorial completion")
 game.spawn_customer()
 var protected := game.queue.first()
 protected.advance(300)
 check(protected.patience_protected and protected.state == CustomerController.State.Waiting and game.rating.value == 4, "First guest has unlimited patience and no penalty")
 game.spawn_customer()
 check(game.queue.customers.size() == 1, "No impatient crowd behind protected first guest")
 game.campaign_view.dialogue.next_button.pressed.emit()
 game.campaign_view.dialogue.next_button.pressed.emit()
 check(runtime.tutorial.step == 1, "Welcome advances by real dialogue buttons")
 Input.action_press("move_right")
 for i in 24: await physics_frame
 Input.action_release("move_right")
 check(runtime.tutorial.step >= 2, "Real WASD physics advances training")
 deliver_cookie(game)
 check(runtime.tutorial.step == 6 and runtime.stats.amount("deliveries") == 1, "Actual E pickup and delivery advance training")
 game.cashier.advance(2)
 check(runtime.tutorial.step == 7 and runtime.stats.amount("served") == 1 and runtime.crystals.balance == 5, "Actual service triggers tutorial and first-sale achievement")
 deliver_cookie(game)
 deliver_cookie(game)
 check(runtime.tutorial.step == 8 and runtime.stats.amount("deliveries") == 3, "Three real deliveries count in campaign")
 game.toggle_management(&"development")
 check(paused and runtime.tutorial.step == 9, "Development menu step pauses world")
 game.toggle_management(&"personnel")
 check(paused and runtime.tutorial.done, "Personnel visit completes training")
 check(game.management_menu.action_buttons[&"COOKIE"].tooltip_text == "Повар уже работает", "Management immediately refreshes tutorial purchase lock")
 game.handle_escape()
 deliver_cookie(game)
 deliver_cookie(game)
 for i in 20: game.economy.record_sale()
 check(game.development.buy(&"COFFEE") and runtime.campaign.stage == 2, "Real purchase closes chapter one after cumulative goals")
 check(game.personnel.hire(&"COFFEE") and game.development.buy(&"CUPCAKE") and game.personnel.hire(&"CUPCAKE"), "Real staffing and equipment events update progression")
 check(runtime.tray_upgrades.upgrade(1) and game.tray.capacity == 8 and game.hud_view.labels.tray.text.ends_with("8"), "Upgraded capacity appears in live HUD")
 for i in 99: game.events.publish(&"CustomerServed", {"customer_id":1000 + i}, "fixture:%d" % i)
 check(runtime.campaign.stage == 3 and game.zones.is_open(3) and game.zone_visuals.has(3), "Campaign chapter two opens physical Zone3 without debug API")
 check(game.campaign_view.dialogue.lines[0].to_lower().contains("торт"), "Sophie advice follows current chapter rather than repeating the tutorial")
 check(game.development.buy(&"CAKE") and game.personnel.hire(&"CAKE"), "Cake available through campaign progression")
 game.rating.value = 4.98
 game.rating.changed.emit()
 for product in ProductCatalog.all(): game.checkout.add(4, product.id)
 game.spawn_customer()
 var first := game.queue.first()
 first.position = game.queue.slot(first)
 first.state = CustomerController.State.Waiting
 game.cashier.advance(0.7)
 game.spawner.remaining = 6.25
 var data := runtime.get_save_data()
 check(runtime.load_save_data(roundtrip(data)), "All six managers serialize through JSON together")
 check(not runtime.load_save_data({"version":1}), "Incomplete runtime data rejected")
 var malformed := runtime.get_save_data()
 malformed.stats.erase("served")
 check(not runtime.load_save_data(malformed), "Malformed stats rejected before partial loading")
 check(not runtime.rush.start(false) and not runtime.rush.active, "Rush requires explicit confirmation")
 var checkpoint := runtime.capture_checkpoint()
 check(runtime.rush.start(true) and game.spawner.rush_mode and runtime.rush.remaining == 90, "Confirmed rush creates checkpoint and starts ninety-second trial")
 var interval_ok := true
 for i in 100:
  var interval := game.spawner.next_interval()
  interval_ok = interval_ok and interval >= 3 and interval <= 4
 check(interval_ok and first.patience_limit == 24, "Rush has exact spawn range and twenty-percent patience boost")
 check(not game.development.upgrade(&"COOKIE", 1) and not runtime.tray_upgrades.upgrade(2), "Structural upgrades locked during trial")
 game.cashier.advance(1.3)
 check(runtime.rush.served == 1 and runtime.crystals.balance > int(checkpoint.progression.crystals.balance), "Actual rush service can earn provisional achievement")
 for i in 16: deliver_cookie(game)
 check(runtime.stats.amount("deliveries") >= 20 and runtime.quests.records.q3_trips.complete, "Real trial deliveries can provisionally complete coin quest")
 runtime.rush.advance(40)
 game.toggle_journal()
 var remaining := runtime.rush.remaining
 await create_timer(0.1, true).timeout
 check(runtime.rush.remaining == remaining and paused and game.campaign_view.journal.visible, "Journal pauses Rush timer and game")
 game.handle_escape()
 runtime.rush.advance(50)
 check(runtime.rush.last_result == "failed" and not runtime.rush.active and paused, "Failed rush opens retry view")
 check(game.economy.get_save_data() == checkpoint.world.economy and is_equal_approx(game.rating.value, checkpoint.world.rating), "Rollback restores full economy history, reward ledger and rating")
 check(game.tray.get_save_data() == checkpoint.world.tray and game.checkout.get_save_data() == checkpoint.world.checkout, "Rollback restores every product in tray and checkout")
 check(runtime.get_save_data() == checkpoint.progression, "Rollback restores campaign, quest, achievement, tutorial, crystals, events and upgrade progress")
 check(game.spawner.rng.state == checkpoint.world.rng_state and game.spawner.remaining == checkpoint.world.spawn_remaining and not game.spawner.rush_mode, "Rollback restores random stream and spawn countdown")
 check(game.queue.first().customer_id == checkpoint.world.queue[0] and game.cashier.current == game.queue.first() and is_equal_approx(game.cashier.elapsed, 0.7), "Rollback restores FIFO and in-progress cashier service")
 var all_stations_restored := true
 for id in checkpoint.world.stations:
  var station := game.development.get_station(StringName(id))
  all_stations_restored = all_stations_restored and station.inventory.get_save_data() == checkpoint.world.stations[id].inventory and station.elapsed == checkpoint.world.stations[id].elapsed
 check(all_stations_restored and game.mia.transform == checkpoint.world.mia, "Rollback restores production timers and player transform")
 check(game.capture_rush_state() == checkpoint.world, "Complete gameplay checkpoint matches every captured field after failure")
 game.handle_escape()
 for product in ProductCatalog.all(): game.checkout.add(20, product.id)
 check(runtime.rush.start(true), "Failed rush can be retried with a fresh checkpoint")
 for i in 15:
  if game.queue.first() == null: game.spawn_customer()
  var customer := game.queue.first()
  customer.position = game.queue.slot(customer)
  if customer.state != CustomerController.State.Serving: customer.state = CustomerController.State.Waiting
  game.checkout.add(1,customer.order.product_id) # Bounded stock fixture replenishes requested SKU.
  game.cashier.advance(2)
 check(runtime.rush.won and runtime.rush.served == 15 and runtime.campaign.won, "Fifteen actual cashier services win trial and campaign")
 check(runtime.rewards.claimed.has("campaign:sweet_empire") and runtime.achievements.unlocked.has("campaign_complete"), "Final chapter and completion achievement awarded")
 await process_frame
 await process_frame
 check(game.modal_kind == &"victory" and game.campaign_view.victory_screen != null and paused, "Victory scene overlays preserved bakery")
 game.toggle_management(&"development")
 game.toggle_journal()
 check(game.modal_kind == &"victory" and paused, "Victory cannot be bypassed by management hotkeys")
 var balance := runtime.crystals.balance
 runtime.refresh()
 game.events.publish(&"RushHourCompleted", {}, "final_rush")
 check(runtime.crystals.balance == balance and not runtime.rush.start(true), "Completed Rush and final rewards cannot repeat")
 var victory_buttons := game.campaign_view.victory_screen.find_children("*", "Button", true, false)
 victory_buttons[0].pressed.emit()
 check(runtime.campaign.endless and not paused and game.campaign_view.victory_screen == null, "Victory button resumes same bakery in endless mode")
 check(runtime.load_save_data(roundtrip(runtime.get_save_data())) and runtime.campaign.endless, "Completed endless campaign roundtrip")
 game.toggle_journal()
 game.campaign_view.build_page("achievements")
 check(game.campaign_view.page == "achievements" and paused, "Achievements page is available and pauses game")
 game.toggle_management(&"development")
 check(not game.campaign_view.journal.visible and game.management_menu.visible and paused, "Management replaces journal rather than stacking modals")
 await process_frame
 await process_frame
 check(not game.campaign_view.information_panel.visible, "Campaign HUD cannot cover management cards")
 game.toggle_journal()
 check(game.campaign_view.journal.visible and not game.management_menu.visible and paused, "Journal replaces management with pause preserved")
 game.handle_escape()
 var old_timer := game.production.elapsed
 await create_timer(0.08, true).timeout
 check(game.production.elapsed != old_timer or game.production.inventory.space() == 0, "Production continues in endless mode")
 game.queue_free()
 await process_frame
