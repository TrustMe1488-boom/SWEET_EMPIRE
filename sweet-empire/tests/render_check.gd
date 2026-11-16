extends SceneTree
func _initialize():
 capture.call_deferred()
func capture():
 DisplayServer.window_set_size(Vector2i(1920, 1080))
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 game.production.inventory.add(3)
 game.tray.add(2)
 game.checkout.add(2)
 game.spawn_customer()
 for i in 30: await process_frame
 await RenderingServer.frame_post_draw
 var error := root.get_texture().get_image().save_png("res://Documentation/stage1-bakery.png")
 print("SCREENSHOT_ERROR=", error)
 DisplayServer.window_set_size(Vector2i(960, 540))
 for i in 10: await process_frame
 await RenderingServer.frame_post_draw
 error = root.get_texture().get_image().save_png("res://Documentation/stage1-bakery-small.png")
 print("SCREENSHOT_SMALL_ERROR=", error)
 game.set_paused(true)
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
 error = root.get_texture().get_image().save_png("res://Documentation/stage1-pause.png")
 print("SCREENSHOT_PAUSE_ERROR=", error)
 game.set_paused(false)
 game.queue_free()
 await process_frame
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
 error = root.get_texture().get_image().save_png("res://Documentation/stage1-menu.png")
 print("SCREENSHOT_ERROR=", error)
 quit(error)
