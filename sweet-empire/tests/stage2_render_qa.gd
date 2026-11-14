extends SceneTree
var failures: int = 0
func _initialize():
 run.call_deferred()
func check(condition: bool, description: String):
 print("GPU_CHECK ", "PASS: " if condition else "FAIL: ", description)
 if not condition: failures += 1
func settle(frames: int = 20):
 for i in frames: await process_frame
 await RenderingServer.frame_post_draw
func snapshot(name: String):
 check(root.get_texture().get_image().save_png("res://Documentation/" + name + ".png") == OK, "Saved " + name)
func run():
 if DisplayServer.get_name() == "headless":
  quit(1)
  return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 DisplayServer.window_set_size(Vector2i(1920, 1080))
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 await settle(40)
 await snapshot("stage2-zone1")
 game.toggle_management(&"development")
 await settle()
 await snapshot("stage2-development-locked")
 game.handle_escape()
 # Isolated QA setup only. The live game exposes no funding or Zone3 cheat controls.
 for i in 500: game.economy.record_sale()
 check(game.development.buy(&"COFFEE") and game.personnel.hire(&"COFFEE"), "Coffee purchase and hiring")
 check(game.development.buy(&"CUPCAKE") and game.personnel.hire(&"CUPCAKE"), "Cupcake purchase and hiring")
 game.mia.position = Vector3(0, 0.05, -5.8)
 await settle(200)
 await snapshot("stage2-zone2")
 check(game.zones.unlock_zone3_for_testing(), "Debug Zone3")
 check(game.development.buy(&"CAKE") and game.personnel.hire(&"CAKE"), "Cake purchase and hiring")
 game.development.upgrade(&"COOKIE", 1)
 game.development.upgrade(&"COFFEE", 1)
 game.tray.add(1, &"COOKIE")
 game.tray.add(1, &"COFFEE")
 game.tray.add(1, &"CUPCAKE")
 game.tray.add(1, &"CAKE")
 for product in ProductCatalog.all():
  game.development.get_station(product.id).advance(18)
  game.checkout.add(3, product.id)
 for i in 5:
  game.spawn_customer()
  if game.queue.customers.size() > i:
   var customer: CustomerController = game.queue.customers[i]
   customer.position = game.queue.slot(customer)
   customer.state = CustomerController.State.Waiting
 await settle(150)
 var times: Array[float] = []
 var last := Time.get_ticks_usec()
 var drawcalls: float = 0
 for i in 180:
  await process_frame
  var now := Time.get_ticks_usec()
  times.append((now - last) / 1000.0)
  last = now
  drawcalls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 var mean: float = 0
 for value in times: mean += value
 mean /= times.size()
 times.sort()
 print("STAGE2_BENCHMARK 1920x1080 zones=3 vsync=off frames=180 mean_ms=%.3f median_ms=%.3f p95_ms=%.3f mean_fps=%.2f draw_calls=%.1f" % [mean, times[90], times[171], 1000.0 / mean, drawcalls / 180])
 game.set_paused(true)
 game.pause_panel.hide()
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  var bounds := Rect2(Vector2.ZERO, game.hud_view.size)
  for card in game.hud_view.cards.values(): check(bounds.encloses(card.get_global_rect()), "HUD within " + str(resolution))
  for product in ProductCatalog.all(): check(game.camera.is_position_in_frustum(product.world_position + Vector3.UP), "Station in frame " + str(product.id) + str(resolution))
  check(game.camera.is_position_in_frustum(Vector3(6.6, 1, 4.5)), "Entrance in frame " + str(resolution))
  await snapshot("stage2-all-zones-%dx%d" % [resolution.x, resolution.y])
  for menu in [&"development", &"personnel"]:
   game.toggle_management(menu)
   await settle()
   for button in game.management_menu.action_buttons.values(): check(bounds.encloses(button.get_global_rect()), "Management action within " + str(resolution))
   await snapshot("stage2-%s-%dx%d" % [menu, resolution.x, resolution.y])
  game.set_paused(true)
  game.pause_panel.hide()
 game.set_paused(false)
 game.queue_free()
 await process_frame
 print("STAGE2_GPU_RESULT failures=", failures)
 quit(0 if failures == 0 else 1)
