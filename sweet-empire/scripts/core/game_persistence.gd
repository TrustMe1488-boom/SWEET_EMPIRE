class_name GamePersistence
extends RefCounted
static func capture(game: BakeryGame) -> Dictionary:
 return {"version":1,"world":game.capture_rush_state(),"progression":game.progression.get_save_data(),"zones":game.zones.highest_open(),"rush":{"active":game.progression.rush.active,"remaining":game.progression.rush.remaining,"served":game.progression.rush.served,"ids":game.progression.rush.served_ids.duplicate(),"checkpoint":game.progression.rush.checkpoint.duplicate(true)}}
static func _shape(value: Variant, example: Variant) -> bool:
 if typeof(value) != typeof(example): return false
 if value is float: return is_finite(value)
 if value is Vector3 or value is Transform3D: return value.is_finite()
 if value is Dictionary:
  for key in example:
   if not value.has(key) or not _shape(value[key], example[key]): return false
 return true
static func validate(data: Dictionary, game: BakeryGame = null) -> bool:
 if data.get("version") != 1 or not data.get("world") is Dictionary or not data.get("progression") is Dictionary: return false
 if not data.get("zones") is int or data.zones < 1 or data.zones > 3: return false
 if not data.get("rush") is Dictionary or not _shape(data.rush, {"active":false,"remaining":0.0,"served":0,"ids":{},"checkpoint":{}}): return false
 var world: Dictionary = data.world
 var template := {"pedestrians":{},"demand":{},"predictor":{},"economy":{},"rating":0.0,"tray":{},"checkout":{},"stations":{},"customers":[],"queue":[],"cashier_id":0,"cashier_elapsed":0.0,"spawn_remaining":0.0,"rng_seed":0,"rng_state":0,"rush_mode":false,"mia":Transform3D.IDENTITY,"mia_velocity":Vector3.ZERO,"camera":Transform3D.IDENTITY,"camera_size":0.0,"next_customer_id":0,"last_near":0}
 if not _shape(world, template): return false
 var runtime := CampaignRuntime.new()
 var valid_progression := runtime.validate_save_data(data.progression)
 runtime.free()
 if not valid_progression: return false
 if not world.stations.has("COOKIE") or world.stations.size() > 4 or world.customers.size() > 64 or world.queue.size() > 5: return false
 var tray := TrayInventory.new()
 var tray_level: int = int(data.progression.get("tray",{}).get("level",0))
 if tray_level < 1 or tray_level > 3: return false
 tray.capacity = TrayUpgradeManager.CAPACITIES[tray_level - 1]
 if world.tray.get("capacity") != tray.capacity: return false
 if not tray.load_save_data(world.tray) or not CheckoutInventory.new().load_save_data(world.checkout): return false
 for id in world.stations:
  var product := ProductCatalog.find(StringName(id))
  if product == null or product.zone > data.zones: return false
  var station = world.stations[id]
  if not station is Dictionary or not _shape(station, {"level":1,"has_cook":true,"elapsed":0.0,"inventory":{}}): return false
  if station.level < 1 or station.level > 5 or station.elapsed < 0: return false
  if station.inventory.get("capacity") != 5: return false
  var inventory := StationInventory.new()
  inventory.allowed_product_id = product.id
  if not inventory.load_save_data(station.inventory): return false
 var ids: Dictionary = {}
 for row in world.customers:
  if not row is Dictionary or not _shape(row,{"id":1,"order":"COOKIE","position":Vector3.ZERO,"state":0,"patience":0.0,"limit":0.0,"protected":false,"purchased":false,"age":0.0,"customer_type":"NORMAL","base_patience":0.0,"rotation":0.0,"appearance":{"color":Color.WHITE,"skin":Color.WHITE,"variant":0}}): return false
  if ids.has(row.id) or ProductCatalog.find(StringName(row.order)) == null or row.state < 0 or row.state > CustomerController.State.Leave: return false
  ids[row.id] = true
 var queued: Dictionary = {}
 for id in world.queue:
  if not ids.has(id) or queued.has(id): return false
  queued[id] = true
 if world.cashier_id != -1 and not queued.has(world.cashier_id): return false
 if not _shape(world.economy,{"balance":0,"history":[],"spent":{},"rewards":{}}) or world.economy.balance < 0: return false
 for row in world.economy.history:
  if not row is Dictionary or not _shape(row,{"sequence":1,"category":&"sale","subject":&"COOKIE","amount":0,"balance":0}): return false
 if not _shape(world.demand,{"time":0.0,"records":[],"history":[]}): return false
 if world.demand.records.size()>DemandDataCollector.MAX_RECORDS or world.demand.history.size()>DemandDataCollector.MAX_RECORDS: return false
 for row in world.demand.records + world.demand.history:
  if not row is Dictionary or not row.get("time") is float or not row.get("event") is String: return false
 for row in world.demand.history:
  if str(row.get("product","")) not in DemandDataCollector.IDS or row.get("customer_type") not in ["NORMAL","IMPATIENT","SWEET_TOOTH"]: return false
 if not _shape(world.pedestrians,{"next_id":1,"counts":{"potential":{},"missed":{},"entries":{},"full_queue":0},"visitors":[],"appearance_seed":0,"appearance_state":0}): return false
 for row in world.pedestrians.visitors:
  if not row is Dictionary or not _shape(row,{"id":1,"desired":"COOKIE","type":"NORMAL","route":[],"waypoint":0,"position":Vector3.ZERO,"decided":false,"appearance":{"color":Color.WHITE,"skin":Color.WHITE,"variant":0}}): return false
  if row.route.is_empty() or row.route.size()>8 or row.waypoint<0 or row.waypoint>=row.route.size(): return false
  if ProductCatalog.find(StringName(row.desired)) == null or row.type not in ["NORMAL","IMPATIENT","SWEET_TOOTH"]: return false
  for point in row.route:
   if not point is Vector3 or not point.is_finite(): return false
 if not _shape(world.predictor,{"forecast":[],"last_update":0.0,"signature":"","source":""}) or world.predictor.forecast.size()!=4: return false
 # The current checkpoint decoder is trusted only after the same structural validation.
 if data.rush.active:
  if not _shape(data.rush.checkpoint,{"world":{},"progression":{}}): return false
  var checkpoint := data.duplicate(true)
  checkpoint.world = data.rush.checkpoint.world
  checkpoint.progression = data.rush.checkpoint.progression
  checkpoint.rush.active = false
  if not validate(checkpoint,game): return false
 return true
static func restore(data: Dictionary, game: BakeryGame) -> bool:
 if not validate(data,game): return false
 # Validate progression on the isolated candidate before any existing session is replaced.
 if not game.progression.load_save_data(data.progression): return false
 game.progression.suspended = true
 if data.zones >= 2: game.zones.open_zone2()
 if data.zones >= 3: game.zones.unlock_zone3_for_campaign(true)
 for id in data.world.stations:
  var station := game.development.get_station(StringName(id))
  if station == null:
   station = ProductionStation.new()
   station.configure(ProductCatalog.find(StringName(id)),false)
   game.development.stations[StringName(id)] = station
   game.development.add_child(station)
   game.on_station_purchased(station)
  if data.world.stations[id].has_cook: game.on_cook_hired(station)
 game.restore_rush_state(data.world)
 # Replaying visual construction must not advance event deduplication or grant rewards.
 if not game.progression.load_save_data(data.progression): return false
 game.progression.rush.active = data.rush.active
 game.progression.rush.remaining = data.rush.remaining
 game.progression.rush.served = data.rush.served
 game.progression.rush.served_ids = data.rush.ids.duplicate()
 game.progression.rush.checkpoint = data.rush.checkpoint.duplicate(true)
 game.progression.suspended = false
 game.campaign_view.refresh()
 game.update_hud()
 return true
