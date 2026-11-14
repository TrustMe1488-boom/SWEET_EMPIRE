extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize(): run.call_deferred()
func check(condition: bool, description: String):
 if condition: passed += 1
 else: failed += 1
 print("CAMPAIGN_SIM ", "PASS: " if condition else "FAIL: ", description)
func path_length(product: ProductDefinition) -> float:
 var checkout := Vector3(1.3, 0, -1)
 var access := product.world_position + Vector3(0, 0, 1.25)
 if product.zone == 1: return checkout.distance_to(access)
 var doorway := Vector3(0, 0, -5.4)
 var result := checkout.distance_to(doorway)
 if product.zone == 3:
  result += 5
  doorway.z = -10.4
 return result + doorway.distance_to(access)
func run():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game)
 if game.campaign_view == null or game.progression == null:
  push_error("Campaign scene failed to load")
  quit(1)
  return
 await process_frame
 var runtime := game.progression
 game.campaign_view.dialogue.advance()
 game.campaign_view.dialogue.advance()
 Input.action_press("move_right")
 for i in 24: await physics_frame
 Input.action_release("move_right")
 game.toggle_management(&"development")
 game.toggle_management(&"personnel")
 game.handle_escape()
 game.process_mode = Node.PROCESS_MODE_DISABLED
 game.spawner.rng.seed = 20261114
 var phase := "choose"
 var destination: ProductionStation
 var travel: float = 0
 var elapsed: float = 0
 var stages: Dictionary = {1:0.0}
 var first_coffee: float = -1
 var first_hire: float = -1
 var rush_start: float = -1
 var balances_nonnegative := true
 var dt: float = 0.25
 # The driver budgets walking time at 4 m/s through doorway waypoints.
 # It invokes real E interactions only after arrival, never credits coins directly.
 for tick in 24000:
  elapsed += dt
  for station in game.development.stations.values(): station.advance(dt)
  game.spawner._process(dt)
  game.pedestrians.advance(dt)
  for customer in game.queue.customers.duplicate(): customer.advance(dt)
  game.cashier.advance(dt)
  if not runtime.rush.active:
   if phase == "choose":
    var lowest: float = INF
    destination = null
    for product in game.development.orderable_products():
     var station := game.development.get_station(product.id)
     var stock: int = game.checkout.amount_for(product.id)
     var score: float = stock
     if game.queue.first() != null and game.queue.first().order.product_id == product.id and stock == 0: score -= 100
     if station.inventory.count > 0 and stock < mini(15,game.checkout.limit_for(product.id)) and score < lowest:
      lowest = score
      destination = station
    if destination != null:
     travel = path_length(destination.product) / 4.0 + 0.2
     phase = "outbound"
   else:
    travel -= dt
    if travel <= 0:
     if phase == "outbound":
      game.mia.position = destination.product.world_position + Vector3(0, 0, 1.25)
      game._process(0)
      game.interact()
      travel = path_length(destination.product) / 4.0 + 0.2
      phase = "returning"
     else:
      game.mia.position = game.CHECKOUT_ACCESS
      game._process(0)
      game.interact()
      phase = "choose"
  if runtime.tutorial.done and not runtime.rush.active:
   if game.development.get_station(&"COFFEE") == null and game.economy.coins >= 200:
    if game.development.buy(&"COFFEE"): first_coffee = elapsed
   var coffee := game.development.get_station(&"COFFEE")
   if coffee != null and not coffee.has_cook and game.economy.coins >= 100:
    if game.personnel.hire(&"COFFEE"): first_hire = elapsed
   if runtime.campaign.stage >= 2:
    if game.production.level == 1 and game.economy.coins >= 50: game.development.upgrade(&"COOKIE", 1)
    if runtime.tray_upgrades.level == 1 and game.economy.coins >= 150: runtime.tray_upgrades.upgrade(1)
    if game.development.get_station(&"CUPCAKE") == null and game.economy.coins >= 600: game.development.buy(&"CUPCAKE")
    var cupcake := game.development.get_station(&"CUPCAKE")
    if cupcake != null and not cupcake.has_cook and game.economy.coins >= 200: game.personnel.hire(&"CUPCAKE")
   if game.zones.is_open(3):
    if game.development.get_station(&"CAKE") == null and game.economy.coins >= 1500: game.development.buy(&"CAKE")
    var cake := game.development.get_station(&"CAKE")
    if cake != null and not cake.has_cook and game.economy.coins >= 400: game.personnel.hire(&"CAKE")
   if runtime.campaign.can_start_rush(runtime.stats) and game.checkout.level<3:
    game.checkout_upgrades.upgrade(game.checkout.level)
   if runtime.campaign.can_start_rush(runtime.stats) and game.checkout.level==3 and phase == "choose":
    var prepared := ProductCatalog.all().all(func(product): return game.checkout.amount_for(product.id) >= mini(15,game.checkout.limit_for(product.id)))
    if prepared and runtime.rush.start(true): rush_start = elapsed
  if runtime.rush.active: runtime.rush.advance(dt)
  if not stages.has(runtime.campaign.stage):
   stages[runtime.campaign.stage] = elapsed
   print("CAMPAIGN_SIM_STAGE ", runtime.campaign.stage, " at ", elapsed)
  balances_nonnegative = balances_nonnegative and game.economy.coins >= 0
  if runtime.campaign.won or runtime.rush.last_result == "failed": break
  if tick % 30 == 0: await process_frame
 check(runtime.tutorial.done, "Tutorial completed from real movement, pickup, delivery, service and menu events")
 check(first_coffee > 0 and first_hire > first_coffee, "Coffee and cook funded by normal play")
 check(stages.has(2) and stages.has(3) and game.zones.is_open(3), "All campaign stages and normal Zone3 unlock reached")
 check(runtime.stats.amount("served") >= 100 and runtime.stats.amount("rating") >= 4.5, "Final service count and rating reached")
 check(rush_start > 0 and runtime.rush.won and runtime.rush.served == 15, "Prepared checkout supports fifteen services in real timed Rush without extra delivery")
 check(runtime.campaign.won and balances_nonnegative, "Campaign won with nonnegative balance")
 var allowed_rewards := game.economy.history.all(func(entry): return entry.category != &"reward" or str(entry.subject).begins_with("quest:"))
 check(allowed_rewards, "Every coin comes from product sales or authored quest rewards, no test funding")
 check(game.development.stations.size() == 4 and game.tray.capacity == 8, "Required equipment and tray purchased at agreed prices")
 var all_quests := runtime.quests.records.values().all(func(record): return record.complete)
 check(all_quests and runtime.achievements.unlocked.size() == 6, "All nine Sophie quests and six achievements reachable")
 print("CAMPAIGN_BALANCE elapsed=%.2f coffee=%.2f coffee_hire=%.2f stage2=%.2f stage3=%.2f rush_start=%.2f rush_duration=%.2f served=%d sales_income=%d coins=%d gems=%d left=%d" % [elapsed, first_coffee, first_hire, stages.get(2, -1), stages.get(3, -1), rush_start, 90 - runtime.rush.remaining, int(runtime.stats.amount("served")), int(runtime.stats.amount("sales_income")), game.economy.coins, runtime.crystals.balance, int(runtime.stats.amount("left"))])
 await process_frame
 await process_frame
 check(game.campaign_view.victory_screen != null, "Natural campaign victory scene appears")
 game.queue_free()
 paused = false
 await process_frame
 print("CAMPAIGN_SIM_RESULT: %d passed, %d failed" % [passed, failed])
 quit(0 if failed == 0 else 1)
