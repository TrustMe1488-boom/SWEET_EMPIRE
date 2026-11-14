class_name BakeryGame
extends Node3D
@export var campaign_enabled: bool = false
var session_owned: bool = false
var _applied_dessert: String = ""
var events := GameEvents.new()
var progression: CampaignRuntime
var campaign_view: CampaignView
var sophie: SophieCharacter
var checkout_upgrades: CheckoutUpgradeManager
var tray_upgrades: TrayUpgradeManager
var _next_customer_id: int = 1
var _last_near: int = 0
var zones := ZoneManager.new()
var development: DevelopmentManager
var personnel: PersonnelManager
var controls:GameInputManager
var gesture_bridge:GestureBridge
var dashboard:GameplayDashboard
var analytics_window:SophieAnalyticsPanel
var management_menu: ManagementMenu
var order_selector := OrderSelector.new()
var utility_ai := CustomerUtilityAI.new()
var pedestrians:PedestrianManager
var demand: DemandDataCollector
var predictor: DemandPredictor
var advisor := SophieAdvisor.new()
var station_visuals: Dictionary = {}
var cook_models: Dictionary = {}
var station_labels: Dictionary = {}
var zone_visuals: Dictionary = {}
var installation_slots: Dictionary = {}
var modal_kind: StringName = &""
var production: ProductionStation
var tray := TrayInventory.new()
var checkout := CheckoutInventory.new()
var economy := EconomySystem.new()
var rating := RatingSystem.new()
var queue := QueueManager.new()
var cashier: CashierController
var spawner: CustomerSpawner
var mia: MiaController
var camera: Camera3D
var hud_view: BakeryHUD
var interior: BakeryInterior
var hud: Label
var hint: Label
var oven_label: Label3D
var checkout_label: Label3D
var pause_panel: Control
var oven_cookies: Node3D
var cashier_visual: ChibiVisual
var cook_visual: ChibiVisual
var animation_time: float = 0.0
const OVEN = Vector3(-3.8, 0, -2.0)
const OVEN_ACCESS = Vector3(-3.8, 0, -0.75)
const CHECKOUT = Vector3(2.7, 0, -1.0)
const CHECKOUT_ACCESS = Vector3(1.3, 0, -1.0)
func _ready():
 var from_menu := CampaignLaunch.consume()
 session_owned = from_menu
 campaign_enabled = campaign_enabled or from_menu
 configure_input()
 build_room()
 add_child(CozyTown.new())
 development = DevelopmentManager.new()
 development.configure(economy, zones)
 add_child(development)
 production = development.get_station(&"COOKIE")
 personnel = PersonnelManager.new(development, economy)
 station_visuals[&"COOKIE"] = interior.oven
 cook_models[&"COOKIE"] = interior.cook
 station_labels[&"COOKIE"] = oven_label
 zones.opened.connect(on_zone_opened)
 development.station_purchased.connect(on_station_purchased)
 personnel.hired.connect(on_cook_hired)
 cashier = CashierController.new()
 cashier.queue = queue
 cashier.stock = checkout
 cashier.economy = economy
 cashier.rating = rating
 add_child(cashier)
 spawner = CustomerSpawner.new()
 spawner.rating = rating
 pedestrians=PedestrianManager.new();pedestrians.game=self
 add_child(pedestrians)
 spawner.spawn_requested.connect(pedestrians.request_pedestrian)
 spawner.set_process(false)
 add_child(spawner)
 mia = MiaController.new()
 mia.name = "Mia"
 add_child(mia)
 mia.position = Vector3(-1.5, 0.05, 0.5)
 mia.interaction_requested.connect(interact)
 camera = Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 13.6
 add_child(camera)
 camera.position = Vector3(12, 13.4, 12)
 camera.look_at(Vector3(0, 1.4, 0))
 camera.current = true
 build_ui()
 for inventory in [production.inventory, tray, checkout]: inventory.changed.connect(update_hud)
 economy.changed.connect(update_hud)
 rating.changed.connect(update_hud)
 queue.changed.connect(update_hud)
 development.changed.connect(update_hud)
 personnel.changed.connect(update_hud)
 tray_upgrades = TrayUpgradeManager.new(tray, economy)
 management_menu.tray_upgrades = tray_upgrades
 checkout_upgrades=CheckoutUpgradeManager.new(checkout,economy)
 management_menu.checkout_upgrades=checkout_upgrades
 _connect_events()
 if campaign_enabled: setup_campaign()
 if progression != null: checkout_upgrades.allowed=progression.operations_allowed
 demand = DemandDataCollector.new()
 demand.game = self
 add_child(demand)
 predictor = DemandPredictor.new()
 predictor.collector = demand
 predictor.load_model()
 add_child(predictor)
 events.occurred.connect(func(kind, data): demand.record(str(kind), data))
 predictor.refresh()
 development.changed.connect(predictor.refresh)
 spawner.mode_changed.connect(predictor.refresh)
 var analytics := SophieAnalyticsPanel.new()
 analytics_window=analytics
 analytics.compact_entry=false
 analytics.game = self
 hud_view.get_parent().add_child(analytics)
 apply_cosmetics(get_node("/root/GameSession").cosmetics)
 if session_owned: get_node("/root/GameSession").bind_game(self)
 get_node("/root/AudioHub").set_music("game")
 events.occurred.connect(get_node("/root/AudioHub").event)
 mia.moved.connect(get_node("/root/AudioHub").footstep)
 spawner.mode_changed.connect(func():get_node("/root/AudioHub").set_music("rush" if spawner.rush_mode else "game");get_node("/root/AudioHub").play_sound("rush_start",3))
 if progression!=null:progression.rewards.granted.connect(_reward_audio)
 controls=GameInputManager.new();add_child(controls);mia.input_manager=controls
 gesture_bridge=GestureBridge.new();add_child(gesture_bridge)
 dashboard=GameplayDashboard.new();dashboard.game=self;get_node("HUD").add_child(dashboard)
 var settings:=ControlSettings.new();settings.game=self;settings.controls=controls;settings.bridge=gesture_bridge;get_node("HUD").add_child(settings)
 update_hud()
func configure_input():
 var actions = {"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "interact": KEY_E, "pause": KEY_ESCAPE, "development": KEY_1, "personnel": KEY_2, "journal": KEY_TAB}
 for action in actions:
  if not InputMap.has_action(action): InputMap.add_action(action)
  var event := InputEventKey.new()
  event.physical_keycode = actions[action]
  if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)
func build_room():
 var world := WorldEnvironment.new()
 var environment := Environment.new()
 environment.background_mode = Environment.BG_COLOR
 environment.background_color = Color("#ded6e5")
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("#fff2de")
 environment.ambient_light_energy = 0.48
 world.environment = environment
 add_child(world)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-55, -25, 0)
 sun.light_energy = 0.16
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 35
 add_child(sun)
 interior = preload("res://scenes/visuals/bakery_interior.tscn").instantiate()
 add_child(interior)
 oven_cookies = interior.oven.cookies
 cook_visual = interior.cook
 cashier_visual = interior.cashier
 oven_label = BakeryVisuals.label(self, OVEN + Vector3(0, 2.15, 0.5), "", 25)
 checkout_label = BakeryVisuals.label(self, CHECKOUT + Vector3(1, 2.05, 0.4), "", 25)
func build_ui():
 var layer := CanvasLayer.new()
 layer.name = "HUD"
 layer.process_mode = Node.PROCESS_MODE_ALWAYS
 add_child(layer)
 hud_view = BakeryHUD.new()
 layer.add_child(hud_view)
 hud = hud_view.brand
 hint = hud_view.context_label
 pause_panel = hud_view.pause_panel
 hud_view.pause_buttons[0].pressed.connect(func(): set_paused(false))
 hud_view.pause_buttons[1].pressed.connect(func():
  get_node("/root/GameSession").return_to_menu(self))
 hud_view.pause_buttons[2].pressed.connect(func(): get_node("/root/AudioHub").quit_game())
 var pause_input := Node.new()
 pause_input.set_script(preload("res://scripts/ui/pause_input.gd"))
 pause_input.process_mode = Node.PROCESS_MODE_ALWAYS
 pause_input.game = self
 layer.add_child(pause_input)
 management_menu = preload("res://scenes/ui/management_menu.tscn").instantiate()
 management_menu.development = development
 management_menu.personnel = personnel
 management_menu.economy = economy
 layer.add_child(management_menu)
 management_menu.close_requested.connect(func(): set_paused(false))
 hud_view.development_requested.connect(func(): toggle_management(&"development"))
 hud_view.personnel_requested.connect(func(): toggle_management(&"personnel"))
func set_paused(value: bool):
 get_tree().paused = value
 modal_kind = &"pause" if value else &""
 management_menu.hide()
 if campaign_view != null: campaign_view.hide_modals()
 pause_panel.visible = value
 if value: hud_view.pause_buttons[0].grab_focus()
func toggle_management(kind: StringName):
 if modal_kind == &"victory": return
 if campaign_view != null: campaign_view.hide_modals()
 if modal_kind == kind:
  set_paused(false)
  return
 modal_kind = kind
 get_tree().paused = true
 pause_panel.hide()
 management_menu.open_menu(kind)
 events.publish(&"MenuOpened", {"menu":str(kind)})
 management_menu.refresh()
func handle_escape():
 if modal_kind == &"victory": return
 if modal_kind != &"": set_paused(false)
 else: set_paused(true)
func _process(delta: float):
 var highest := zones.highest_open()
 var center_z: float = -2.5 * (highest - 1)
 var follow := 0.08 if highest == 1 else 0.22
 var focus := Vector3(0.7 + clampf(mia.position.x * follow, -0.8, 0.8), 1.4, center_z + clampf((mia.position.z - center_z) * follow, -1.5, 1.5))
 camera.position = camera.position.lerp(focus + Vector3(12, 12, 12), 4 * delta)
 camera.size = lerpf(camera.size, 14.8 + 3.7 * (highest - 1), minf(1, delta * 2))
 camera.look_at(camera.position - Vector3(12, 12, 12))
 var target := nearest_station()
 if target != _last_near:
  _last_near = target
  if target != 0: events.publish(&"NearStation", {"station":"checkout" if target == 2 else "oven"})
 var message := ""
 var selected := station_for_interaction(target)
 if selected != null:
  message = "Забрать: " + selected.product.display_name
  if not selected.has_cook: message = "Нужен повар · меню 2"
  elif selected.inventory.count == 0: message = "Продукция готовится…"
  elif tray.space() == 0: message = "Поднос заполнен"
 if target == 2: message = "Передать всё на кассу" if tray.count > 0 else "Поднос пока пуст"
 hud_view.show_context(target, message)
 for id in station_visuals:
  var station := development.get_station(id)
  var visual: EquipmentVisual = station_visuals[id]
  var running: bool = station.has_cook and station.inventory.space() > 0
  visual.running = running
  visual.progress = station.elapsed / station.production_time()
  if cook_models.has(id): cook_models[id].set_state(&"Working" if running else &"Idle")
 cashier_visual.set_state(&"Serving" if cashier.current != null else &"Idle")
func station_for_interaction(index: int) -> ProductionStation:
 var ids := {1: &"COOKIE", 3: &"COFFEE", 4: &"CUPCAKE", 5: &"CAKE"}
 return development.get_station(ids[index]) if ids.has(index) else null
func nearest_station() -> int:
 var nearest: int = 0
 var distance: float = 1.5
 var checkout_distance := mia.position.distance_to(CHECKOUT_ACCESS)
 if checkout_distance <= distance:
  distance = checkout_distance
  nearest = 2
 for index in [1, 3, 4, 5]:
  var station := station_for_interaction(index)
  if station == null: continue
  var point := station.product.world_position + Vector3(0, 0, 1.25)
  var separation := mia.position.distance_to(point)
  if separation <= distance:
   distance = separation
   nearest = index
 return nearest
func interact():
 var target := nearest_station()
 if target == 0: return
 mia.play_interaction()
 if target == 2:
  var items := tray.contents()
  var transferred := DeliveryService.deliver(tray, checkout)
  if transferred > 0:
   var delivered:Dictionary={}
   for id in items:
    var amount:int=int(items[id])-tray.amount_for(id)
    if amount>0:delivered[id]=amount
   events.publish(&"ProductDelivered", {"items":delivered, "amount":transferred})
 else:
  var station := station_for_interaction(target)
  var taken := station.inventory.transfer_to(tray)
  if taken > 0: events.publish(&"ProductPickedUp", {"product":station.product.id, "amount":taken})
func update_hud():
 if hud == null: return
 var first := queue.first()
 var id: StringName = first.order.product_id if first != null else &"COOKIE"
 var descriptions: PackedStringArray = []
 for product in ProductCatalog.all():
  var station := development.get_station(product.id)
  if station != null: descriptions.append("%s ур.%d%s" % [product.display_name, station.level, "" if station.has_cook else " (без повара)"])
 hud_view.refresh(economy.coins, rating.value, tray.count, queue.customers.size(), first != null, id, "Станции: " + " · ".join(descriptions), tray.contents(), checkout.contents(), tray.capacity)
 var stock_lines:PackedStringArray=[]
 for product in ProductCatalog.all():stock_lines.append("%s %d/%d"%[product.display_name,checkout.amount_for(product.id),checkout.limit_for(product.id)])
 hud_view.stock_label.text="Касса · "+" · ".join(stock_lines)
 checkout_label.text = "КАССА  ·  %d" % checkout.count
 mia.show_inventory(tray)
 for product_id in station_visuals:
  var station := development.get_station(product_id)
  var visual: EquipmentVisual = station_visuals[product_id]
  station_labels[product_id].text = "%s · %d / 5%s" % [station.product.display_name.to_upper(), station.inventory.count, "" if station.has_cook else " · нужен повар"]
  var ready_products: Node3D = visual.cookies
  for child in ready_products.get_children():
   ready_products.remove_child(child)
   child.queue_free()
  for i in station.inventory.count:
   BakeryVisuals.product(ready_products, Vector3((i % 3 - 1) * 0.35, 1.44 if product_id == &"COOKIE" else 1.33, floori(i / 3.0) * 0.3 + (0.0 if product_id == &"COOKIE" else 0.25)), product_id)
 if management_menu.visible: management_menu.refresh()
func spawn_customer(desired:CustomerOrder=null, requested_type:String="", appearance:Dictionary={}) -> CustomerController:
 if queue.customers.size() >= QueueManager.CAPACITY: return null
 if progression != null and not progression.tutorial.first_served and progression.tutorial.first_customer_spawned: return null
 var type:String = requested_type if not requested_type.is_empty() else utility_ai.choose_type(spawner.rng)
 if _next_customer_id <= 3: type = "NORMAL" # Introduce ordinary guests before mixed profiles.
 var chosen:CustomerOrder = desired if desired!=null else utility_ai.choose(development.orderable_products(), spawner.rng, type, spawner.rush_mode)
 if chosen!=null and not development.orderable_products().any(func(product):return product.id==chosen.product_id):return null
 if chosen == null: return null
 var customer := _make_customer(chosen, _next_customer_id,appearance)
 if customer == null: return null
 _next_customer_id += 1
 customer.position = Vector3(6, 0, 4.5)
 customer.customer_type = type
 customer.base_patience = utility_ai.patience(type)
 customer.patience_limit = customer.base_patience * (1.2 if spawner.rush_mode else 1.0)
 customer.patience = customer.patience_limit
 if demand != null: demand.record("OrderCreated", {"customer_id":customer.customer_id,"customer_type":type,"product":str(chosen.product_id)})
 if progression != null and not progression.tutorial.first_customer_spawned:
  progression.tutorial.first_customer_spawned = true
  customer.patience_protected = true
 return customer
func _make_customer(chosen: CustomerOrder, id: int, appearance: Dictionary = {}, join_queue: bool = true) -> CustomerController:
 var customer := CustomerController.new()
 customer.queue = queue
 customer.customer_id = id
 customer.assign_order(chosen)
 if join_queue and not queue.join(customer):
  customer.free()
  return null
 add_child(customer)
 var colors := [BakeryVisuals.PINK, BakeryVisuals.MINT, BakeryVisuals.LAVENDER, BakeryVisuals.CARAMEL]
 var color: Color = appearance.color if appearance.has("color") else colors[spawner.rng.randi_range(0, 3)]
 var skin: Color = appearance.get("skin", [Color("#edc1a0"), Color("#d5a383"), Color("#bd886b"), Color("#a9755d")][spawner.rng.randi_range(0, 3)])
 var variant: int = appearance.variant if appearance.has("variant") else spawner.rng.randi_range(0, 3)
 customer.visual = BakeryVisuals.person(customer, color, false, skin, variant)
 customer.indicator = BakeryVisuals.label(customer, Vector3(0, 2.07, 0), "", 18)
 customer.setup_patience_indicator()
 customer.abandoned.connect(_customer_left)
 return customer
func _customer_left(customer: CustomerController):
 rating.adjust(-0.10)
 events.publish(&"CustomerLeft", {"customer_id":customer.customer_id,"customer_type":customer.customer_type,"product":str(customer.order.product_id)}, str(customer.customer_id))

func on_zone_opened(zone: int):
 if zone == 2: interior.open_expansion_passage()
 elif zone == 3: zone_visuals[2].open_passage()
 var area: ExpansionZone = preload("res://scenes/visuals/expansion_zone.tscn").instantiate()
 area.zone = zone
 add_child(area)
 area.position = Vector3(0, 0, -8 - (zone - 2) * 5)
 zone_visuals[zone] = area
 for product in ProductCatalog.all():
  if product.zone != zone or development.get_station(product.id) != null: continue
  var slot := Node3D.new()
  area.get_node("VisualRoot").add_child(slot)
  slot.global_position = product.world_position
  BakeryVisuals.cylinder(slot, Vector3(0, 0.03, 0), 0.82, 0.04, BakeryVisuals.LAVENDER)
  BakeryVisuals.label(slot, Vector3(0, 0.7, 0), "МЕСТО УСТАНОВКИ\n" + product.station_name, 23)
  installation_slots[product.id] = slot
 events.publish(&"ZoneUnlocked", {"zone":zone}, str(zone))
 if mia != null: apply_cosmetics(get_node("/root/GameSession").cosmetics)
func on_station_purchased(station: ProductionStation):
 var product := station.product
 if installation_slots.has(product.id):
  installation_slots[product.id].queue_free()
  installation_slots.erase(product.id)
 var visual: EquipmentVisual = load(product.visual_scene).instantiate()
 add_child(visual)
 visual.position = product.world_position
 station_visuals[product.id] = visual
 station_labels[product.id] = BakeryVisuals.label(self, product.world_position + Vector3(0, 2.6, 0.65), "", 23)
 station.inventory.changed.connect(update_hud)
 _watch_station(station)
 events.publish(&"EquipmentPurchased", {"product":product.id}, str(product.id))
 if mia != null: apply_cosmetics(get_node("/root/GameSession").cosmetics)
 update_hud()
func on_cook_hired(station: ProductionStation):
 if cook_models.has(station.product.id): return
 var actor := Node3D.new()
 actor.name = str(station.product.station_id) + "Cook"
 add_child(actor)
 actor.position = station.product.world_position + Vector3(0, 0, -1.6)
 var model := BakeryVisuals.person(actor, BakeryVisuals.CREAM, true, Color("#d5a383"), 0, "cook")
 model.rotation.y = PI
 cook_models[station.product.id] = model
 events.publish(&"ChefHired", {"product":station.product.id}, str(station.product.id))
 update_hud()

func _watch_station(station: ProductionStation):
 station.produced.connect(func(id, amount): events.publish(&"ProductProduced", {"product":id, "amount":amount}))
func _connect_events():
 _watch_station(production)
 economy.sale_recorded.connect(func(id, price): events.publish(&"ProductSold", {"product":id, "price":price}))
 cashier.customer_served.connect(func(customer): events.publish(&"CustomerServed", {"customer_id":customer.customer_id, "product":customer.order.product_id}, str(customer.customer_id)))
 rating.changed.connect(func(): events.publish(&"RatingChanged", {"value":rating.value}))
 development.station_upgraded.connect(func(station): events.publish(&"StationUpgraded", {"product":station.product.id, "level":station.level}, "%s:%d" % [station.product.id, station.level]))
 mia.moved.connect(func(distance):
  if progression != null and not progression.tutorial.done: events.publish(&"MiaMoved", {"distance":distance}))
func setup_campaign():
 sophie = preload("res://scenes/visuals/sophie.tscn").instantiate()
 add_child(sophie)
 sophie.position = Vector3(-5.2, 0, 0.1)
 progression = CampaignRuntime.new()
 if session_owned: progression.crystals = get_node("/root/GameSession").wallet
 progression.configure(self, events)
 add_child(progression)
 tray_upgrades = progression.tray_upgrades
 management_menu.tray_upgrades = tray_upgrades
 campaign_view = CampaignView.new()
 campaign_view.runtime = progression
 campaign_view.game = self
 get_node("HUD").add_child(campaign_view)
 progression.refresh()
func toggle_journal():
 if campaign_view == null: return
 if modal_kind == &"journal": set_paused(false)
 elif modal_kind != &"victory": campaign_view.show_journal("quests")
func show_victory():
 if campaign_view != null: campaign_view.show_victory()
func capture_rush_state() -> Dictionary:
 var stations: Dictionary = {}
 for id in development.stations:
  var station: ProductionStation = development.stations[id]
  stations[str(id)] = {"level":station.level, "has_cook":station.has_cook, "elapsed":station.elapsed, "inventory":station.inventory.get_save_data()}
 var customers: Array[Dictionary] = []
 for child in get_children():
  if child is CustomerController and not child.is_queued_for_deletion():
   var model: ChibiVisual = child.visual
   customers.append({"id":child.customer_id, "order":str(child.order.product_id), "position":child.position, "state":int(child.state), "patience":child.patience, "limit":child.patience_limit, "protected":child.patience_protected, "purchased":child.purchased, "age":child.age,"street_exit":child.street_exit,"street_leg":child.street_leg, "customer_type":child.customer_type, "base_patience":child.base_patience, "appearance":{"color":model.clothing, "skin":model.skin, "variant":model.variant}, "rotation":model.rotation.y})
 var order: Array[int] = []
 for customer in queue.customers: order.append(customer.customer_id)
 return {"pedestrians":pedestrians.get_save_data(), "demand":demand.get_save_data(), "predictor":predictor.get_save_data(), "economy":economy.get_save_data(), "rating":rating.value, "tray":tray.get_save_data(), "checkout":checkout.get_save_data(), "stations":stations, "customers":customers, "queue":order, "cashier_id":cashier.current.customer_id if cashier.current != null else -1, "cashier_elapsed":cashier.elapsed, "spawn_remaining":spawner.remaining, "rng_seed":spawner.rng.seed, "rng_state":spawner.rng.state, "rush_mode":spawner.rush_mode, "mia":mia.transform, "mia_velocity":mia.velocity, "camera":camera.transform, "camera_size":camera.size, "next_customer_id":_next_customer_id, "last_near":_last_near}
func restore_rush_state(data: Dictionary):
 cashier.current = null
 queue.customers.clear()
 for child in get_children():
  if child is CustomerController:
   remove_child(child)
   child.queue_free()
 economy.load_save_data(data.economy)
 rating.value = float(data.rating)
 tray.load_save_data(data.tray)
 checkout.load_save_data(data.checkout)
 for id in data.stations:
  var station := development.get_station(StringName(id))
  station.level = int(data.stations[id].level)
  station.has_cook = bool(data.stations[id].has_cook)
  station.elapsed = float(data.stations[id].elapsed)
  station.inventory.load_save_data(data.stations[id].inventory)
 var restored: Dictionary = {}
 for record in data.customers:
  var customer := _make_customer(CustomerOrder.new(StringName(record.order)), int(record.id), record.appearance, false)
  customer.position = record.position
  customer.state = int(record.state)
  customer.patience = float(record.patience)
  customer.patience_limit = float(record.limit)
  customer.patience_protected = bool(record.protected)
  customer.purchased = bool(record.purchased)
  customer.age = float(record.age)
  customer.street_exit=bool(record.get("street_exit",false))
  customer.street_leg=int(record.get("street_leg",0))
  customer.customer_type = str(record.get("customer_type","NORMAL"))
  customer.base_patience = float(record.get("base_patience",20))
  customer.visual.rotation.y = float(record.rotation)
  customer.update_visual(0)
  restored[customer.customer_id] = customer
 for id in data.queue: queue.customers.append(restored[int(id)])
 cashier.current = restored.get(int(data.cashier_id))
 cashier.elapsed = float(data.cashier_elapsed)
 spawner.rng.seed = int(data.rng_seed)
 spawner.rng.state = int(data.rng_state)
 spawner.remaining = float(data.spawn_remaining)
 spawner.rush_mode = bool(data.rush_mode)
 mia.transform = data.mia
 mia.velocity = data.mia_velocity
 camera.transform = data.camera
 camera.size = float(data.camera_size)
 _next_customer_id = int(data.next_customer_id)
 _last_near = int(data.last_near)
 if data.has("pedestrians"):pedestrians.load_save_data(data.pedestrians)
 if data.has("demand"): demand.load_save_data(data.demand)
 if data.has("predictor"): predictor.load_save_data(data.predictor)
 queue.changed.emit()

func apply_cosmetics(manager: CosmeticManager):
 CosmeticVisualApplicator.apply_outfit(mia.visual,manager.active("MIA_OUTFIT"))
 var theme_definition:=manager.active("INTERIOR_THEME")
 CosmeticVisualApplicator.apply_theme(interior,theme_definition)
 for area in zone_visuals.values():CosmeticVisualApplicator.apply_theme(area,theme_definition)
 for visual in station_visuals.values():CosmeticVisualApplicator.apply_theme(visual,theme_definition)
 var style:=manager.active("DESSERT_STYLE").style
 if not _applied_dessert.is_empty() and _applied_dessert!=style.detail:CosmeticVisualApplicator.refresh_products(self)
 _applied_dessert=style.detail
 _cutaway()
 update_hud()

func open_analytics():
 if campaign_view!=null:campaign_view.show_journal("analytics")
 else:analytics_window.open()

func _reward_audio(id:String,_title:String,_coins:int,gems:int):
 get_node("/root/AudioHub").play_sound("celebrate" if id.begins_with("achievement:") or id.begins_with("campaign:") else "quest",3)
 if gems>0:get_node("/root/AudioHub").play_sound("crystal",2)

func _cutaway():
 if zones.highest_open()>=2:_hide_back_strip(interior.get_node("VisualRoot"),-5.0)
 if zones.highest_open()>=3 and zone_visuals.has(2):_hide_back_strip(zone_visuals[2].get_node("VisualRoot"),-10.0)
func _hide_back_strip(root:Node,boundary:float):
 for visual in root.find_children("*","VisualInstance3D",true,false):
  if visual.global_position.z<boundary and visual.global_position.y>0.8:visual.hide()
