extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize():
 run.call_deferred()
func check(condition: bool, description: String):
 if condition: passed += 1
 else: failed += 1
 print("STAGE2 ", "PASS: " if condition else "FAIL: ", description)
func fund(wallet: EconomySystem, amount: int):
 for i in amount / 10: wallet.record_sale()
func run():
 var expected_prices := [10, 20, 40, 80]
 var expected_purchase := [0, 200, 600, 1500]
 var expected_hire := [0, 100, 200, 400]
 var expected_times := [4.0, 6.0, 9.0, 15.0]
 var products := ProductCatalog.all()
 for i in products.size():
  var product := products[i]
  check(product.sale_price == expected_prices[i] and product.base_time == expected_times[i], "Configured product " + str(product.id))
  check(product.purchase_cost == expected_purchase[i] and product.hire_cost == expected_hire[i], "Configured purchase and hire costs " + str(product.id))
  check(product.upgrade_cost(1) == 50 * (i + 1), "Configured upgrade factor " + str(product.id))
  var station := ProductionStation.new()
  station.configure(product)
  station.advance(100)
  check(station.inventory.count == 0 and station.elapsed == 0, "No cook means no production " + str(product.id))
  station.has_cook = true
  station.advance(product.base_time - 0.01)
  check(station.inventory.count == 0, "No early batch " + str(product.id))
  station.advance(0.01)
  check(station.inventory.amount_for(product.id) == 1, "Correct product and base time " + str(product.id))
  station.advance(1000)
  check(station.inventory.count == 5, "Capacity five " + str(product.id))
  station.inventory.take(1)
  station.advance(product.base_time)
  check(station.inventory.count == 5, "Production resumes " + str(product.id))
  station.free()
 var wallet := EconomySystem.new()
 var zones := ZoneManager.new()
 var development := DevelopmentManager.new()
 development.configure(wallet, zones)
 var personnel := PersonnelManager.new(development, wallet)
 check(wallet.coins == 0 and development.get_station(&"COOKIE").has_cook, "Free initial oven and cook, zero balance")
 check(not development.buy(&"COFFEE") and wallet.coins == 0 and wallet.history.is_empty(), "Insufficient funds never charged")
 check(not zones.unlock_zone3_for_testing() and zones.highest_open() == 1, "Zone3 debug unlock requires Zone2")
 check(not development.buy(&"CUPCAKE") and development.last_error.contains("Сначала"), "Cupcake requires Zone2 even before funds check")
 fund(wallet, 200)
 check(development.buy(&"COFFEE") and wallet.coins == 0 and zones.is_open(2), "Coffee purchase 200 opens Zone2")
 var coffee := development.get_station(&"COFFEE")
 check(coffee != null and not coffee.has_cook and coffee.level == 1, "Purchase includes no cook")
 var transaction_count := wallet.history.size()
 check(not development.buy(&"COFFEE") and wallet.history.size() == transaction_count, "Duplicate purchase not charged")
 check(not personnel.hire(&"COFFEE") and wallet.coins == 0, "Hire requires funds")
 check(development.orderable_products().size() == 1, "Unstaffed product excluded from orders")
 fund(wallet, 100)
 check(personnel.hire(&"COFFEE") and wallet.coins == 0 and coffee.has_cook, "Hire for 100 starts coffee production")
 transaction_count = wallet.history.size()
 check(not personnel.hire(&"COFFEE") and wallet.history.size() == transaction_count, "Duplicate hire not charged")
 check(personnel.workplaces().size() == 2 and development.orderable_products().size() == 2, "Personnel and active assortment")
 check(not personnel.hire(&"CAKE"), "Cannot hire without equipment")
 var selector := OrderSelector.new()
 var rng := RandomNumberGenerator.new()
 rng.seed = 42
 var chosen_ids: Dictionary = {}
 for i in 500:
  var order := selector.choose(development.orderable_products(), rng)
  chosen_ids[order.product_id] = true
 check(chosen_ids.size() == 2 and chosen_ids.has(&"COOKIE") and chosen_ids.has(&"COFFEE"), "Selector uses staffed products only")
 var immutable := CustomerController.new()
 check(immutable.assign_order(CustomerOrder.new(&"COFFEE")) and not immutable.assign_order(CustomerOrder.new(&"COOKIE")) and immutable.order.product_id == &"COFFEE", "Order cannot be changed")
 immutable.free()
 check(not development.upgrade(&"COOKIE") and wallet.coins == 0 and development.get_station(&"COOKIE").level == 1, "Upgrade rejects insufficient funds")
 fund(wallet, 5000)
 check(not development.buy(&"CAKE"), "Cake cannot bypass locked Zone3")
 check(zones.unlock_zone3_for_testing() and not zones.unlock_zone3_for_testing(), "Debug Zone3 unlock is idempotent")
 var purchase_balance := wallet.coins
 check(development.buy(&"CUPCAKE") and development.buy(&"CAKE") and wallet.coins == purchase_balance - 2100, "Zone-appropriate cupcake and cake purchases")
 purchase_balance = wallet.coins
 check(personnel.hire(&"CUPCAKE") and personnel.hire(&"CAKE") and wallet.coins == purchase_balance - 600, "Cooks hired on their own stations")
 var last_operations := wallet.history
 check(last_operations.back().category == &"hire" and last_operations.back().amount == -400, "Expense history records category and amount")
 last_operations.back().amount = 999
 check(wallet.history.back().amount == -400, "History returned as an isolated snapshot")
 check(not wallet.try_spend(-1, &"equipment", &"X", "negative"), "Negative expenses rejected")
 check(not wallet.record_sale(&"INVALID"), "Unknown product gives no income")
 var cookie := development.get_station(&"COOKIE")
 cookie.advance(2)
 var before := wallet.coins
 check(development.upgrade(&"COOKIE", 1) and wallet.coins == before - 50 and cookie.level == 2, "First upgrade costs fifty once")
 check(is_equal_approx(cookie.production_time(), 3.4) and is_equal_approx(cookie.elapsed / cookie.production_time(), 0.5), "Upgrade preserves progress and applies time formula")
 before = wallet.coins
 check(not development.upgrade(&"COOKIE", 1) and wallet.coins == before, "Stale upgrade action cannot charge twice")
 for level in [2, 3, 4]:
  before = wallet.coins
  check(development.upgrade(&"COOKIE", level) and wallet.coins == before - 50 * level, "Upgrade cost at level %d" % level)
 before = wallet.coins
 check(cookie.level == 5 and not development.upgrade(&"COOKIE") and wallet.coins == before, "Level five maximum without extra charge")
 check(is_equal_approx(cookie.production_time(), 4 * pow(0.85, 4)), "Level-five production time")
 for id in [&"COFFEE", &"CUPCAKE", &"CAKE"]:
  var station := development.get_station(id)
  before = wallet.coins
  check(development.upgrade(id, 1) and wallet.coins == before - station.product.upgrade_cost(1), "Product-specific upgrade cost " + str(id))
 var tray := TrayInventory.new()
 tray.add(2, &"COOKIE")
 tray.add(1, &"COFFEE")
 tray.add(2, &"CUPCAKE")
 check(tray.count == 5 and tray.add(1, &"CAKE") == 0, "Mixed tray has shared capacity five")
 check(tray.add(-3, &"COOKIE") == 0 and tray.take(-1, &"COFFEE") == 0, "Negative inventory operations rejected")
 check(tray.add(1, &"INVALID") == 0 and tray.add(1, &"CoffeeMachine") == 0, "Inventories accept only canonical product IDs")
 var unknown := TrayInventory.new()
 check(unknown.add(1, &"INVALID") == 0 and unknown.add(1, &"CoffeeMachine") == 0 and unknown.count == 0, "Invalid product rejected even when tray has room")
 var checkout := CheckoutInventory.new()
 var observed: Array[bool] = []
 var on_tray_change := func(): observed.append(tray.count == 0 and checkout.count == 5 and checkout.amount_for(&"COFFEE") == 1)
 tray.changed.connect(on_tray_change)
 var on_checkout_change := func(): observed.append(tray.count == 0 and checkout.count == 5)
 checkout.changed.connect(on_checkout_change)
 check(DeliveryService.deliver(tray, checkout) == 5 and observed.size() == 2 and observed.all(func(value): return value), "Atomic multi-product commit before signals")
 tray.changed.disconnect(on_tray_change)
 checkout.changed.disconnect(on_checkout_change)
 check(checkout.amount_for(&"COOKIE") == 2 and checkout.amount_for(&"COFFEE") == 1 and checkout.amount_for(&"CUPCAKE") == 2, "Checkout keeps separate stock")
 check(DeliveryService.deliver(tray, checkout) == 0, "Repeated delivery cannot duplicate items")
 var detached := checkout.contents()
 detached[&"COOKIE"] = 500
 check(checkout.amount_for(&"COOKIE") == 2, "Inventory snapshot cannot mutate stock")
 var limited := StationInventory.new()
 check(limited.add(1, &"COFFEE") == 0, "Cookie station rejects other products")
 # Selling must consume exactly the ordered type and use configured prices.
 var sale_wallet := EconomySystem.new()
 var rating := RatingSystem.new()
 for product in products:
  var stock := CheckoutInventory.new()
  stock.add(2, product.id)
  stock.add(3, &"COOKIE" if product.id != &"COOKIE" else &"COFFEE")
  var customer := CustomerController.new()
  customer.assign_order(CustomerOrder.new(product.id))
  customer.state = CustomerController.State.Serving
  var coins_before := sale_wallet.coins
  check(SaleProcessor.complete(customer, stock, sale_wallet, rating) and stock.amount_for(product.id) == 1 and stock.count == 4 and sale_wallet.coins == coins_before + product.sale_price, "Sale of exact product " + str(product.id))
  check(not SaleProcessor.complete(customer, stock, sale_wallet, rating), "No repeat purchase " + str(product.id))
  customer.free()
 check(sale_wallet.coins == 150 and is_equal_approx(rating.value, 4.08), "All configured sale prices and rating increments")
 var no_coffee := CheckoutInventory.new()
 no_coffee.add(5)
 var queue := QueueManager.new()
 var first := CustomerController.new()
 first.queue = queue
 first.assign_order(CustomerOrder.new(&"COFFEE"))
 first.state = CustomerController.State.Waiting
 queue.join(first)
 var second := CustomerController.new()
 second.queue = queue
 second.state = CustomerController.State.Waiting
 queue.join(second)
 var cashier := CashierController.new()
 cashier.queue = queue
 cashier.stock = no_coffee
 cashier.economy = sale_wallet
 cashier.rating = rating
 var no_substitution_balance := sale_wallet.coins
 cashier.advance(5)
 check(cashier.current == null and sale_wallet.coins == no_substitution_balance and queue.first() == first, "Missing requested product blocks FIFO without substitution")
 first.advance(20)
 cashier.advance(2)
 check(first.state == CustomerController.State.Leave and second.purchased and sale_wallet.coins == no_substitution_balance + 10, "Timeout clears blocked order and FIFO resumes")
 first.free()
 second.free()
 cashier.free()
 development.free()
 # Composed scene: real menus, new geometry, interactions, pause and navigation.
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.mia.position = Vector3(0, 0.05, -4.5)
 Input.action_press("move_up")
 Input.action_press("move_right")
 for i in 25: await physics_frame
 Input.action_release("move_up")
 Input.action_release("move_right")
 check(game.mia.position.z > -5.1, "Locked Zone2 wall blocks movement")
 game.toggle_management(&"development")
 check(paused and game.management_menu.visible and not game.pause_panel.visible, "Development UI pauses game")
 check(game.management_menu.action_buttons[&"COFFEE"].disabled, "Unaffordable purchase disabled in UI")
 fund(game.economy, 5000)
 check(not game.management_menu.action_buttons[&"COFFEE"].disabled, "Purchase button reflects available balance")
 game.management_menu.action_buttons[&"COFFEE"].pressed.emit()
 check(game.zones.is_open(2) and game.zone_visuals.has(2) and game.station_visuals.has(&"COFFEE") and paused, "UI purchase adds real room and machine while remaining paused")
 check(not game.cook_models.has(&"COFFEE"), "No phantom employee after buying")
 game.toggle_management(&"personnel")
 check(paused and game.management_menu.mode == &"personnel", "Switch between management menus preserves pause")
 game.management_menu.action_buttons[&"COFFEE"].pressed.emit()
 check(game.cook_models.has(&"COFFEE") and game.development.get_station(&"COFFEE").has_cook, "UI hiring adds visible cook")
 var timer := game.development.get_station(&"COFFEE").elapsed
 await create_timer(0.1, true).timeout
 check(game.development.get_station(&"COFFEE").elapsed == timer, "New production also paused by management")
 game.handle_escape()
 check(not paused and not game.management_menu.visible, "Escape closes management and resumes")
 game.mia.position = Vector3(0, 0.05, -4.5)
 Input.action_press("move_up")
 Input.action_press("move_right")
 for i in 60: await physics_frame
 Input.action_release("move_up")
 Input.action_release("move_right")
 check(game.mia.position.z < -6.5 and game.mia.position.y > -0.1, "Mia physically walks through Zone1 to Zone2")
 check(game.development.buy(&"CUPCAKE") and game.personnel.hire(&"CUPCAKE"), "Cupcake installed and staffed in scene")
 check(game.zones.unlock_zone3_for_testing() and game.zone_visuals.has(3), "Debug unlock creates Zone3 geometry")
 check(game.development.buy(&"CAKE") and game.personnel.hire(&"CAKE"), "Cake installed and staffed for testing")
 game.mia.position = Vector3(0, 0.05, -9.8)
 Input.action_press("move_up")
 Input.action_press("move_right")
 for i in 25: await physics_frame
 Input.action_release("move_up")
 Input.action_release("move_right")
 check(game.mia.position.z < -10.7 and game.mia.position.y > -0.1, "Mia physically crosses Zone2 to Zone3")
 # Close management via physical hotkey input and reopen the other menu.
 var hotkey := InputEventKey.new()
 hotkey.physical_keycode = KEY_1
 hotkey.pressed = true
 Input.parse_input_event(hotkey)
 Input.flush_buffered_events()
 await process_frame
 await process_frame
 check(paused and game.management_menu.mode == &"development", "Hotkey 1 opens development")
 hotkey = InputEventKey.new()
 hotkey.physical_keycode = KEY_2
 hotkey.pressed = true
 Input.parse_input_event(hotkey)
 Input.flush_buffered_events()
 await process_frame
 await process_frame
 check(paused and game.management_menu.mode == &"personnel", "Hotkey 2 switches to personnel while paused")
 game.handle_escape()
 var real_coffee := game.development.get_station(&"COFFEE")
 real_coffee.inventory.add(3)
 game.mia.position = real_coffee.product.world_position + Vector3(0, 0, 1.25)
 game.interact()
 check(game.tray.amount_for(&"COFFEE") > 0, "New machine uses real E interaction point")
 game.mia.position = game.CHECKOUT_ACCESS
 var total_before := game.economy.coins
 game.interact()
 check(game.checkout.amount_for(&"COFFEE") > 0 and game.tray.count == 0 and game.economy.coins == total_before, "Mixed delivery still gives no coins")
 game.spawn_customer()
 check(game.queue.first() != null and game.development.orderable_products().any(func(product): return product.id == game.queue.first().order.product_id), "Composed customer order drawn from active assortment")
 check(game.hud_view.stations_label.text.contains("Кофе") and game.hud_view.stock_label.text.contains("Кофе"), "HUD shows stations and separate stock")
 game.toggle_management(&"development")
 check(game.management_menu.action_buttons[&"CAKE"].disabled == (game.economy.coins < 200), "Management reflects purchased station upgrade")
 game.set_paused(false)
 game.queue_free()
 await process_frame
 # Deterministic transfer stress: shared capacities and per-product conservation.
 var source := ItemInventory.new()
 var mixed_tray := TrayInventory.new()
 var sink := CheckoutInventory.new()
 var random := RandomNumberGenerator.new()
 random.seed = 1234
 for definition in products: source.add(50, definition.id)
 var conserved := true
 for i in 1000:
  var id := products[random.randi_range(0, 3)].id
  match random.randi_range(0, 3):
   0: source.transfer_to(mixed_tray, id)
   1: mixed_tray.transfer_to(sink)
   2: sink.transfer_to(mixed_tray, id)
   3: mixed_tray.transfer_to(source)
  conserved = conserved and mixed_tray.count <= 5
  for definition in products:
   conserved = conserved and source.amount_for(definition.id) + mixed_tray.amount_for(definition.id) + sink.amount_for(definition.id) == 50
 check(conserved, "One thousand mixed transfers conserve each product and shared capacity")
 await balance_simulation()
 print("STAGE2_RESULT: %d passed, %d failed" % [passed, failed])
 quit(0 if failed == 0 else 1)
func balance_simulation():
 # Test driver collects and delivers every three seconds, never creates income.
 var wallet := EconomySystem.new()
 var zones := ZoneManager.new()
 var dev := DevelopmentManager.new()
 dev.configure(wallet, zones)
 dev.process_mode = Node.PROCESS_MODE_DISABLED
 root.add_child(dev)
 var staff := PersonnelManager.new(dev, wallet)
 var queue := QueueManager.new()
 var stock := CheckoutInventory.new()
 var tray := TrayInventory.new()
 var rating := RatingSystem.new()
 var cashier := CashierController.new()
 cashier.queue = queue
 cashier.stock = stock
 cashier.economy = wallet
 cashier.rating = rating
 var stage := Node3D.new()
 stage.process_mode = Node.PROCESS_MODE_DISABLED
 root.add_child(stage)
 var until_spawn: float = 8
 var until_delivery: float = 3
 var coffee_at: float = -1
 var hire_at: float = -1
 for tick in 6000:
  var time := tick * 0.1
  dev.get_station(&"COOKIE").advance(0.1)
  until_delivery -= 0.1
  if until_delivery <= 0:
   dev.get_station(&"COOKIE").inventory.transfer_to(tray)
   DeliveryService.deliver(tray, stock)
   until_delivery += 3
  until_spawn -= 0.1
  if until_spawn <= 0:
   until_spawn += 9.0 / rating.spawn_factor()
   if queue.customers.size() < 5:
    var visitor := CustomerController.new()
    visitor.queue = queue
    queue.join(visitor)
    stage.add_child(visitor)
    visitor.position = queue.slot(visitor)
    visitor.state = CustomerController.State.Waiting
    visitor.abandoned.connect(func(_visitor): rating.adjust(-0.1))
  for visitor in queue.customers.duplicate(): visitor.advance(0.1)
  cashier.advance(0.1)
  if coffee_at < 0 and wallet.coins >= 200:
   if dev.buy(&"COFFEE"): coffee_at = time
  if coffee_at >= 0 and wallet.coins >= 100:
   if staff.hire(&"COFFEE"):
    hire_at = time
    break
 check(coffee_at > 0 and hire_at > coffee_at, "Starting from zero, cookie sales alone fund coffee purchase and cook")
 check(wallet.history.filter(func(entry): return entry.category == &"sale").all(func(entry): return entry.subject == &"COOKIE"), "Balance simulation income comes only from real cookie sales")
 print("BALANCE_SIM coffee_purchase_seconds=%.1f coffee_hire_seconds=%.1f balance=%d" % [coffee_at, hire_at, wallet.coins])
 cashier.free()
 dev.queue_free()
 stage.queue_free()
 await process_frame
