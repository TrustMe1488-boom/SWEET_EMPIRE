extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize():
 run.call_deferred()
func check(condition: bool, description: String):
 if condition:
  passed += 1
  print("PASS: ", description)
 else:
  failed += 1
  push_error("FAIL: " + description)
func run():
 var station := ProductionStation.new()
 station.advance(3.99)
 check(station.inventory.count == 0, "No early production")
 station.advance(0.01)
 check(station.inventory.count == 1, "One cookie in four seconds")
 station.advance(100)
 check(station.inventory.count == 5, "Oven capacity five")
 station.advance(100)
 var tray := TrayInventory.new()
 check(station.inventory.transfer_to(tray) == 5 and tray.count == 5 and station.inventory.count == 0, "Atomic pickup conserves cookies")
 station.advance(3.99)
 check(station.inventory.count == 0, "No accumulated production while full")
 station.advance(0.01)
 check(station.inventory.count == 1, "Production resumes after pickup")
 check(station.inventory.transfer_to(tray) == 0 and station.inventory.count == 1, "Full tray rejects transfer")
 check(tray.add(20) == 0 and tray.count == 5, "Tray capacity five")
 check(tray.transfer_to(tray) == 0 and tray.count == 5, "Self transfer cannot duplicate")
 var stock := CheckoutInventory.new()
 var economy := EconomySystem.new()
 var rating := RatingSystem.new()
 check(DeliveryService.deliver(tray, stock) == 5 and tray.count == 0 and stock.count == 5, "Delivery transfers all items")
 check(economy.coins == 0, "Delivery gives no coins")
 check(DeliveryService.deliver(tray, stock) == 0 and stock.count == 5, "Repeated empty delivery gives no duplicate")
 var queue := QueueManager.new()
 var visitors: Array[CustomerController] = []
 for i in 6:
  var visitor := CustomerController.new()
  visitor.queue = queue
  visitors.append(visitor)
  check(queue.join(visitor) == (i < 5), "Queue admission %d" % i)
 check(queue.customers.size() == 5 and queue.first() == visitors[0], "Queue capacity and FIFO")
 var cashier := CashierController.new()
 cashier.queue = queue
 cashier.stock = stock
 cashier.economy = economy
 cashier.rating = rating
 visitors[0].state = CustomerController.State.Waiting
 cashier.advance(1.99)
 check(economy.coins == 0 and stock.count == 5, "Service takes two seconds")
 cashier.advance(0.01)
 check(economy.coins == 10, "Sale awards exactly ten coins")
 check(stock.count == 4 and visitors[0].purchased, "Sale consumes one cookie")
 check(is_equal_approx(rating.value, 4.02), "Sale rating plus 0.02")
 check(queue.first() == visitors[1], "Queue advances after sale")
 visitors[0].state = CustomerController.State.Serving
 check(not SaleProcessor.complete(visitors[0], stock, economy, rating) and economy.coins == 10 and stock.count == 4, "No second purchase")
 visitors[1].state = CustomerController.State.Waiting
 visitors[1].abandoned.connect(func(_visitor): rating.adjust(-0.1))
 visitors[1].advance(20.0)
 check(visitors[1].state == CustomerController.State.Leave and not queue.customers.has(visitors[1]), "Customer leaves after twenty seconds")
 check(is_equal_approx(rating.value, 3.92), "Abandonment rating minus 0.10")
 rating.adjust(-100)
 check(rating.value == 1.0 and is_equal_approx(rating.spawn_factor(), 0.7), "Rating lower clamp and factor")
 rating.adjust(100)
 check(rating.value == 5.0 and is_equal_approx(rating.spawn_factor(), 1.1), "Rating upper clamp and factor")
 var spawner := CustomerSpawner.new()
 spawner.rating = rating
 var interval_ok := true
 for i in 100:
  var interval := spawner.next_interval()
  interval_ok = interval_ok and interval >= 8.0 / 1.1 and interval <= 10.0 / 1.1
 check(interval_ok, "Spawn interval equals uniform 8 to 10 divided by factor")
 stock.take(100)
 visitors[2].state = CustomerController.State.Waiting
 cashier.advance(10)
 check(cashier.current == null and economy.coins == 10, "Cashier waits for stock")
 for visitor in visitors: visitor.free()
 station.free()
 cashier.free()
 spawner.free()
 # Test the actual composed scene, input actions and paused process tree.
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.mia != null and game.camera.current and game.hud.text.contains("SWEET EMPIRE"), "Bakery scene and HUD load")
 game.production.inventory.add(5)
 game.mia.position = game.OVEN_ACCESS
 game.interact()
 check(game.tray.count == 5 and game.production.inventory.count == 0, "Actual oven interaction")
 game.mia.position = game.CHECKOUT_ACCESS
 game.interact()
 check(game.tray.count == 0 and game.checkout.count == 5 and game.economy.coins == 0, "Actual checkout interaction gives no coins")
 game.spawn_customer()
 var first := game.queue.first()
 first.position = game.queue.slot(first)
 first.state = CustomerController.State.Waiting
 await process_frame
 var production_time := game.production.elapsed
 var patience := first.patience
 var visitor_position := first.position
 var sale_time := game.cashier.elapsed
 var spawn_time := game.spawner.remaining
 game.set_paused(true)
 await create_timer(0.15, true).timeout
 check(is_equal_approx(game.production.elapsed, production_time), "Pause freezes production")
 check(is_equal_approx(first.patience, patience) and first.position == visitor_position, "Pause freezes visitor patience and movement")
 check(is_equal_approx(game.cashier.elapsed, sale_time) and game.economy.coins == 0, "Pause freezes sales")
 check(is_equal_approx(game.spawner.remaining, spawn_time), "Pause freezes spawning")
 check(game.pause_panel.visible and game.pause_panel.can_process(), "Pause menu works while paused")
 var escape := InputEventKey.new()
 escape.physical_keycode = KEY_ESCAPE
 escape.pressed = true
 Input.parse_input_event(escape)
 await process_frame
 check(not paused and not game.pause_panel.visible, "Escape resumes through always-processing input")
 game.mia.position = Vector3(-1, 0.05, 2)
 var start := game.mia.position
 Input.action_press("move_right")
 for i in 15: await physics_frame
 Input.action_release("move_right")
 check(game.mia.position.distance_to(start) > 0.3, "Mia moves with camera-relative input")
 game.mia.position = Vector3(-3.8, 0.05, -0.5)
 Input.action_press("move_up")
 Input.action_press("move_left")
 for i in 45: await physics_frame
 Input.action_release("move_up")
 Input.action_release("move_left")
 check(game.mia.position.z > -1.1, "Oven collision blocks Mia")
 game.mia.position = Vector3(0, 0.05, 4.7)
 Input.action_press("move_down")
 Input.action_press("move_right")
 for i in 45: await physics_frame
 Input.action_release("move_down")
 Input.action_release("move_right")
 check(game.mia.position.z < 5.15, "Front boundary collision blocks Mia")
 # Accelerate just this integration run to exercise automatic spawning, queue and sales.
 Engine.time_scale = 20.0
 await create_timer(3.0).timeout
 Engine.time_scale = 1.0
 check(game.economy.coins >= 10 and game.checkout.count <= 4, "Composed game automatically completes a sale")
 game.queue_free()
 await process_frame
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 await process_frame
 var buttons := menu.find_children("*", "Button", true, false)
 check(menu.find_child("NewGameButton",true,false) != null and menu.find_child("ContinueButton",true,false) != null and menu.find_child("SettingsButton",true,false) != null and menu.find_child("ExitButton",true,false) != null and buttons[0].pressed.get_connections().size() >= 1, "Main menu buttons connected")
 current_scene = menu
 buttons[0].pressed.emit()
 await process_frame
 await process_frame
 check(current_scene is BakeryGame, "Start button opens BakeryGame")
 var started_game: BakeryGame = current_scene
 started_game.set_paused(true)
 var pause_buttons := started_game.pause_panel.find_children("*", "Button", true, false)
 pause_buttons[0].pressed.emit()
 check(not paused, "Continue button resumes game")
 started_game.set_paused(true)
 pause_buttons[1].pressed.emit()
 await process_frame
 await process_frame
 check(not paused and current_scene is Control, "Pause menu returns to main menu and clears pause")
 current_scene.queue_free()
 await process_frame
 print("RESULT: %d passed, %d failed" % [passed, failed])
 quit(0 if failed == 0 else 1)
