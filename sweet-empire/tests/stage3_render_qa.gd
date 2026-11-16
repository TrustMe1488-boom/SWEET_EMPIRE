extends SceneTree
var failures: int = 0
func _initialize(): run.call_deferred()
func check(value: bool, title: String):
 print("STAGE3_GPU ", "PASS: " if value else "FAIL: ", title)
 if not value: failures += 1
func settle(frames: int = 20):
 for i in frames: await process_frame
 await RenderingServer.frame_post_draw
func snapshot(name: String):
 check(root.get_texture().get_image().save_png("res://Documentation/" + name + ".png") == OK, "Saved " + name)
func delivery(game: BakeryGame, product: StringName):
 var station := game.development.get_station(product)
 station.advance(station.production_time() * 5)
 game.mia.position = station.product.world_position + Vector3(0, 0, 1.25)
 game._process(0)
 game.interact()
 game.mia.position = game.CHECKOUT_ACCESS
 game._process(0)
 game.interact()
func serve(game: BakeryGame):
 if game.queue.first() == null: game.spawn_customer()
 var customer := game.queue.first()
 if customer == null: return
 customer.position = game.queue.slot(customer)
 if customer.state != CustomerController.State.Serving: customer.state = CustomerController.State.Waiting
 game.cashier.advance(2)
func run():
 if DisplayServer.get_name() == "headless":
  quit(1)
  return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 DisplayServer.window_set_size(Vector2i(1920, 1080))
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game)
 if game.campaign_view == null or game.progression == null:
  push_error("Campaign scene failed to load")
  quit(1)
  return
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  await snapshot("stage3-welcome-%dx%d" % [resolution.x, resolution.y])
 game.campaign_view.dialogue.advance()
 game.campaign_view.dialogue.advance()
 Input.action_press("move_right")
 for i in 25: await physics_frame
 Input.action_release("move_right")
 delivery(game, &"COOKIE")
 serve(game)
 for i in 4: delivery(game, &"COOKIE")
 game.toggle_management(&"development")
 game.toggle_management(&"personnel")
 game.handle_escape()
 var runtime := game.progression
 check(runtime.tutorial.done, "Tutorial follows actual inputs and deliveries")
 game.economy.grant_reward("qa_setup", 10000)
 game.development.buy(&"COFFEE")
 game.personnel.hire(&"COFFEE")
 game.development.buy(&"CUPCAKE")
 game.personnel.hire(&"CUPCAKE")
 runtime.tray_upgrades.upgrade(1)
 for product in ProductCatalog.all(): game.checkout.add(80, product.id)
 for i in 100:
  serve(game)
  if game.zones.is_open(3) and game.development.get_station(&"CAKE") == null:
   game.development.buy(&"CAKE")
   game.personnel.hire(&"CAKE")
  if i % 15 == 0: await process_frame
 check(runtime.campaign.stage == 3 and game.zones.is_open(3), "Normal campaign Zone3 opening")
 game.development.upgrade(&"COOKIE", 1)
 runtime.tray_upgrades.upgrade(2)
 for i in 2: delivery(game, &"COFFEE")
 game.campaign_view.dialogue.dismiss()
 game.campaign_view.toast_queue.clear()
 game.campaign_view.toast_label.text = ""
 for product in ProductCatalog.all():
  game.tray.add(3, product.id)
  game.development.get_station(product.id).advance(40)
 game.mia.position = Vector3(-1.5, 0.05, 0.5)
 await settle(160)
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  for page in ["quests", "achievements"]:
   game.campaign_view.show_journal(page)
   await settle()
   await snapshot("stage3-%s-%dx%d" % [page, resolution.x, resolution.y])
  game.toggle_management(&"development")
  await settle()
  check(not game.campaign_view.information_panel.visible, "Management cards not covered by campaign HUD")
  await snapshot("stage3-development-%dx%d" % [resolution.x, resolution.y])
  game.handle_escape()
 DisplayServer.window_set_size(Vector2i(1920, 1080))
 game.campaign_view.show_journal("rush_confirm")
 await settle()
 await snapshot("stage3-rush-confirm")
 game.handle_escape()
 check(runtime.rush.start(true), "Rush confirmed")
 runtime.rush.advance(90)
 await settle()
 await snapshot("stage3-rush-rollback")
 game.handle_escape()
 check(runtime.rush.start(true), "Retry begins from restored state")
 for i in 5: game.spawn_customer()
 await settle(50)
 var samples: Array[float] = []
 var last := Time.get_ticks_usec()
 var draw_calls: float = 0
 for i in 180:
  await process_frame
  var now := Time.get_ticks_usec()
  samples.append((now - last) / 1000.0)
  last = now
  draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 var mean: float = 0
 for value in samples: mean += value
 mean /= samples.size()
 samples.sort()
 print("STAGE3_BENCHMARK 1920x1080 vsync=off zones=3 frames=180 mean_ms=%.3f median_ms=%.3f p95_ms=%.3f fps=%.2f draw_calls=%.1f" % [mean, samples[90], samples[171], 1000 / mean, draw_calls / 180])
 game.set_paused(true)
 game.pause_panel.hide()
 game.modal_kind = &""
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  var bounds := Rect2(Vector2.ZERO, game.hud_view.size)
  for card in game.hud_view.cards.values(): check(bounds.encloses(card.get_global_rect()), "HUD in bounds " + str(resolution))
  check(bounds.encloses(game.campaign_view.stage_label.get_global_rect()) and bounds.encloses(game.campaign_view.gems_label.get_global_rect()), "Campaign HUD in bounds " + str(resolution))
  await snapshot("stage3-rush-%dx%d" % [resolution.x, resolution.y])
 game.set_paused(false)
 while runtime.rush.active: serve(game)
 await settle()
 check(runtime.campaign.won and game.campaign_view.victory_screen != null, "Victory scene loaded")
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  await snapshot("stage3-victory-%dx%d" % [resolution.x, resolution.y])
 var buttons := game.campaign_view.victory_screen.find_children("*", "Button", true, false)
 buttons[0].pressed.emit()
 await settle()
 await snapshot("stage3-endless")
 check(runtime.campaign.endless and not paused, "Endless mode resumes")
 game.queue_free()
 await process_frame
 print("STAGE3_GPU_RESULT failures=", failures)
 quit(0 if failures == 0 else 1)
