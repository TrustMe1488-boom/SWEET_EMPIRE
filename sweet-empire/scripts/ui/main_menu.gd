extends Control
var shop_button: ShopMenuButton
var stage_camera: Camera3D
var stage_time: float = 0.0
var stage_oven: EquipmentVisual
func _ready():
 get_node("/root/AudioHub").set_music("menu")
 theme = BakeryTheme.create()
 var background := ColorRect.new()
 background.color = Color("#ded6e5")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 build_preview()
 var paper := ColorRect.new()
 paper.color = Color("#fff5e6")
 paper.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
 paper.anchor_right = 0.405
 paper.offset_right = 0
 paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(paper)
 var column := VBoxContainer.new()
 column.position = Vector2(56, 70)
 column.size.x = 410
 column.add_theme_constant_override("separation", 14)
 add_child(column)
 var badge := HBoxContainer.new()
 badge.add_theme_constant_override("separation", 8)
 var icon := HudIcon.new()
 icon.kind = "cookie"
 badge.add_child(icon)
 var badge_label := BakeryTheme.text("СДЕЛАНО С ЛЮБОВЬЮ", 14, Color("#a47a70"))
 badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 badge.add_child(badge_label)
 column.add_child(badge)
 var title := BakeryTheme.text("SWEET\nEMPIRE", 70, Color("#76546e"))
 title.add_theme_constant_override("line_spacing", -8)
 column.add_child(title)
 column.add_child(BakeryTheme.text("Маленькая кондитерская.\nБольшая мечта.", 24, Color("#8e788f")))
 var rule := HSeparator.new()
 column.add_child(rule)
 column.add_child(BakeryTheme.text("Испеките немного счастья\nи подарите его каждому гостю.", 17, Color("#95818b")))
 for caption in ["Начать игру", "Выход"]:
  var button := Button.new()
  button.text = caption
  button.custom_minimum_size = Vector2(390, 56)
  button.add_theme_font_size_override("font_size", 23)
  column.add_child(button)
  BakeryTheme.animate_button(button)
  if caption == "Начать игру":
   button.pressed.connect(func():
    get_node("/root/GameSession").start_or_continue())
   if get_node("/root/GameSession").has_game(): button.text="Продолжить"
   button.grab_focus()
   shop_button=ShopMenuButton.new()
   shop_button.name="ShopButton"
   shop_button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ui/cosmetic_shop.tscn"))
   column.add_child(shop_button)
  else:
   button.add_theme_stylebox_override("normal", BakeryTheme.panel(Color("#f2e5e6")))
   button.pressed.connect(func(): get_node("/root/AudioHub").quit_game())
 var caption := BakeryTheme.text("КОНДИТЕРСКАЯ МИИ   /   ДОБРО ПОЖАЛОВАТЬ", 14, Color("#86728e"))
 caption.position = Vector2(590, 36)
 add_child(caption)
 var footer := BakeryTheme.text("Тёплая выпечка · Приятные встречи", 15, Color("#86728e"))
 footer.position = Vector2(605, 666)
 add_child(footer)
 column.modulate.a = 0
 create_tween().tween_property(column, "modulate:a", 1.0, 0.45)
func build_preview():
 var container := SubViewportContainer.new()
 container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 container.anchor_left = 0.405
 container.offset_left = 0
 container.stretch = true
 container.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(container)
 var viewport := SubViewport.new()
 viewport.size = Vector2i(760, 720)
 viewport.own_world_3d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 container.add_child(viewport)
 var stage := Node3D.new()
 viewport.add_child(stage)
 var world := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("#ded6e5")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = BakeryVisuals.CREAM
 env.ambient_light_energy = 0.48
 world.environment = env
 stage.add_child(world)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-55, -25, 0)
 light.light_energy = 0.16
 light.shadow_enabled = true
 light.directional_shadow_max_distance = 35
 stage.add_child(light)
 var interior: BakeryInterior = preload("res://scenes/visuals/bakery_interior.tscn").instantiate()
 stage.add_child(interior)
 CosmeticVisualApplicator.apply_theme(interior,get_node("/root/GameSession").cosmetics.active("INTERIOR_THEME"))
 stage_oven = interior.oven
 interior.cook.set_state(&"Working")
 interior.cashier.set_state(&"Serving")
 for i in 3: BakeryVisuals.cookie(interior.oven.cookies, Vector3((i - 1) * 0.35, 1.44, 0))
 var hero := Node3D.new()
 stage.add_child(hero)
 hero.position = Vector3(-1, 0, 0.4)
 var model := BakeryVisuals.person(hero, BakeryVisuals.CREAM, true)
 CosmeticVisualApplicator.apply_outfit(model,get_node("/root/GameSession").cosmetics.active("MIA_OUTFIT"))
 model.rotation.y = -2.35
 model.show_cookies(3)
 model.set_state(&"CarryIdle")
 for i in 2:
  var guest := Node3D.new()
  stage.add_child(guest)
  guest.position = Vector3(2.7 + i * 1.9, 0, 1.7 + i * 1.5)
  var look := BakeryVisuals.person(guest, BakeryVisuals.MINT if i == 0 else BakeryVisuals.PINK, false, Color("#d5a383"), i + 1)
  look.rotation.y = 0.4
 stage_camera = Camera3D.new()
 viewport.add_child(stage_camera)
 stage_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 stage_camera.size = 18.5
 stage_camera.position = Vector3(12, 12.6, 12)
 stage_camera.look_at(Vector3(0, 0.6, 0))
 stage_camera.current = true
func _process(delta: float):
 stage_time += delta
 if stage_oven:
  stage_oven.running = true
  stage_oven.progress = fmod(stage_time * 0.25, 1.0)
