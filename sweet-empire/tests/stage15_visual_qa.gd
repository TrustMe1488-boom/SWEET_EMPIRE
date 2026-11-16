extends SceneTree
var failures: int = 0
func _initialize():
 run.call_deferred()
func check(condition: bool, description: String):
 print("VISUAL_CHECK ", "PASS: " if condition else "FAIL: ", description)
 if not condition: failures += 1
func settle(frames: int = 12):
 for i in frames: await process_frame
 await RenderingServer.frame_post_draw
func snapshot(filename: String):
 var error := root.get_texture().get_image().save_png("res://Documentation/" + filename + ".png")
 check(error == OK, "Saved " + filename)
func run():
 if DisplayServer.get_name() == "headless":
  push_error("Use a real display for visual QA")
  quit(1)
  return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 DisplayServer.window_set_size(Vector2i(1920, 1080))
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 game.production.inventory.add(3)
 game.tray.add(2)
 game.checkout.add(2)
 for i in 5:
  game.spawn_customer()
  var visitor := game.queue.customers[i]
  visitor.position = game.queue.slot(visitor)
  visitor.state = CustomerController.State.Waiting
 await settle(60)
 var samples: Array[float] = []
 var draw_calls: float = 0
 var previous := Time.get_ticks_usec()
 for i in 180:
  await process_frame
  var now := Time.get_ticks_usec()
  samples.append((now - previous) / 1000.0)
  previous = now
  draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 var average: float = 0
 for sample in samples: average += sample
 average /= samples.size()
 samples.sort()
 print("BENCHMARK resolution=1920x1080 vsync=disabled frames=180 mean_ms=%.3f median_ms=%.3f p95_ms=%.3f mean_fps=%.2f mean_draw_calls=%.1f" % [average, samples[90], samples[171], 1000.0 / average, draw_calls / 180.0])
 # Keep the showroom still for consistent framing checks; this does not change game rules.
 game.set_paused(true)
 game.pause_panel.hide()
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  var bounds := Rect2(Vector2.ZERO, game.hud_view.size)
  for key in game.hud_view.cards:
   check(bounds.encloses(game.hud_view.cards[key].get_global_rect()), "HUD %s at %s" % [key, resolution])
  for point in [game.OVEN + Vector3.UP, game.CHECKOUT + Vector3.UP, Vector3(6.6, 1, 4.5), Vector3(2.7, 1.7, 4.3)]:
   check(game.camera.is_position_in_frustum(point), "Station/visitor in frame at %s" % resolution)
  for x in [-6.0, 6.0]:
   for z in [-5.0, 5.0]:
    check(game.camera.is_position_in_frustum(Vector3(x, 2.05, z)) and game.camera.is_position_in_frustum(Vector3(x, 0, z)), "Mia corner stays in frame at %s" % resolution)
  await snapshot("stage1_5-game-%dx%d" % [resolution.x, resolution.y])
 game.pause_panel.show()
 await settle()
 await snapshot("stage1_5-pause")
 game.set_paused(false)
 game.mia.position = game.OVEN_ACCESS
 await settle(25)
 await snapshot("stage1_5-context")
 # Model sheet uses the same reusable scene and real procedural animation states.
 game.queue_free()
 await process_frame
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 for resolution in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(960, 540)]:
  DisplayServer.window_set_size(resolution)
  await settle(40)
  await snapshot("stage1_5-menu-%dx%d" % [resolution.x, resolution.y])
 menu.queue_free()
 await process_frame
 DisplayServer.window_set_size(Vector2i(1280, 720))
 var sheet := Node3D.new()
 root.add_child(sheet)
 var world := WorldEnvironment.new()
 var environment := Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("#ded6e5")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = BakeryVisuals.CREAM
 environment.ambient_light_energy = 0.48
 world.environment = environment
 sheet.add_child(world)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55, -25, 0)
 light.light_energy = 0.16
 sheet.add_child(light)
 BakeryVisuals.box(sheet, Vector3(0, -0.16, 0), Vector3(12, 0.3, 5), BakeryVisuals.CREAM)
 var sheet_camera := Camera3D.new()
 sheet.add_child(sheet_camera)
 sheet_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 sheet_camera.size = 3.8
 sheet_camera.position = Vector3(1.2, 3.6, 9)
 sheet_camera.look_at(Vector3(0, 0.9, 0))
 sheet_camera.current = true
 var models: Array[Node3D] = []
 for i in 3:
  var anchor := Node3D.new()
  sheet.add_child(anchor)
  anchor.position.x = (i - 1) * 1.6
  var look := BakeryVisuals.person(anchor, BakeryVisuals.CREAM, false, Color("#e4b795"), 0, ["mia", "cook", "cashier"][i])
  look.rotation.y = PI
  look.set_state([&"CarryIdle", &"Working", &"Serving"][i])
  if i == 0: look.show_cookies(3)
  BakeryVisuals.label(anchor, Vector3(0, 0.01, 0.65), ["МИЯ", "ПОВАР", "КАССИР"][i], 22)
  models.append(anchor)
 await settle(30)
 await snapshot("stage1_5-characters")
 for model in models: model.queue_free()
 await process_frame
 sheet_camera.size = 4.8
 for i in 4:
  var anchor := Node3D.new()
  sheet.add_child(anchor)
  anchor.position.x = (i - 1.5) * 1.6
  var look := BakeryVisuals.person(anchor, [BakeryVisuals.PINK, BakeryVisuals.MINT, BakeryVisuals.LAVENDER, BakeryVisuals.CARAMEL][i], false, Color("#e4b795").darkened(i * 0.06), i)
  look.rotation.y = PI
  look.set_state(&"Happy" if i == 3 else &"QueueIdle")
 await settle(30)
 await snapshot("stage1_5-customers")
 sheet.queue_free()
 await process_frame
 print("VISUAL_RESULT failures=", failures)
 quit(0 if failures == 0 else 1)
