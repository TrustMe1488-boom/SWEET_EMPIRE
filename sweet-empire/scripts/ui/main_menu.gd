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
 var scroll := ScrollContainer.new()
 scroll.name = "MenuScroll"
 scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 scroll.anchor_right = 0.405
 scroll.offset_left = 24; scroll.offset_right = -24
 scroll.offset_top = 24; scroll.offset_bottom = -24
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 add_child(scroll)
 var center := CenterContainer.new()
 center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 center.size_flags_vertical = Control.SIZE_EXPAND_FILL
 scroll.add_child(center)
 var column := VBoxContainer.new()
 column.custom_minimum_size.x = 390
 column.add_theme_constant_override("separation", 7)
 center.add_child(column)
 var badge := HBoxContainer.new()
 badge.add_theme_constant_override("separation", 8)
 var icon := HudIcon.new()
 icon.kind = "cookie"
 badge.add_child(icon)
 var badge_label := BakeryTheme.text("СДЕЛАНО С ЛЮБОВЬЮ", 14, Color("#a47a70"))
 badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 badge.add_child(badge_label)
 column.add_child(badge)
 var title := BakeryTheme.text("SWEET\nEMPIRE", 54, Color("#76546e"))
 title.name = "MenuTitle"
 title.add_theme_constant_override("line_spacing", -8)
 column.add_child(title)
 column.add_child(BakeryTheme.text("Маленькая кондитерская.\nБольшая мечта.", 24, Color("#8e788f")))
 var rule := HSeparator.new()
 column.add_child(rule)
 column.add_child(BakeryTheme.text("Испеките немного счастья\nи подарите его каждому гостю.", 17, Color("#95818b")))
 var save_status: String = get_node("/root/GameSession").save_status
 var status_label := BakeryTheme.text(save_status,14)
 status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(status_label)
 var session: GameSessionManager = get_node("/root/GameSession")
 var confirmation := ConfirmationDialog.new()
 confirmation.title = "Новая игра"
 confirmation.dialog_text = "Начать заново? Текущий прогресс будет заменён, его копия сохранится."
 confirmation.ok_button_text = "Начать заново"
 add_child(confirmation)
 confirmation.confirmed.connect(func():
  if not session.new_game(): status_label.text = session.save_status)
 var captions := ["Продолжить", "Новая игра", "Магазин", "Настройки", "Выход"] if session.has_continue() else ["Новая игра", "Продолжить", "Магазин", "Настройки", "Выход"]
 var actions := VBoxContainer.new()
 actions.name = "MenuActions"
 actions.theme = _menu_button_theme()
 actions.add_theme_constant_override("separation", 10)
 column.add_child(actions)
 for caption in captions:
  if caption == "Магазин":
   shop_button = ShopMenuButton.new()
   shop_button.name = "ShopButton"
   shop_button.pressed.connect(func():get_tree().change_scene_to_file("res://scenes/ui/cosmetic_shop.tscn"))
   shop_button.custom_minimum_size = Vector2(0,52)
   shop_button.add_theme_font_size_override("font_size",21)
   actions.add_child(shop_button)
   continue
  var button := Button.new()
  button.text = caption
  button.name = {"Новая игра":"NewGameButton","Продолжить":"ContinueButton","Магазин":"ShopButton","Настройки":"SettingsButton","Выход":"ExitButton"}[caption]
  button.custom_minimum_size.y = 52
  button.add_theme_font_size_override("font_size", 21)
  actions.add_child(button)
  if caption == "Новая игра":
   button.pressed.connect(func():
    if session.has_continue() or FileAccess.file_exists(session.save_store.directory.path_join("save.dat")) or FileAccess.file_exists(session.save_store.directory.path_join("save.previous")): confirmation.popup_centered()
    elif not session.new_game(): status_label.text = session.save_status)
   button.grab_focus()
  elif caption == "Продолжить":
   button.disabled = not session.has_continue()
   button.pressed.connect(session.start_or_continue)
  elif caption == "Настройки":
   button.pressed.connect(show_settings)
  else:
   button.pressed.connect(func(): get_node("/root/AudioHub").quit_game())
 scroll.resized.connect(_adapt_menu)
 _adapt_menu()
 var caption := BakeryTheme.text("КОНДИТЕРСКАЯ МИИ   /   ДОБРО ПОЖАЛОВАТЬ", 14, Color("#86728e"))
 caption.position = Vector2(590, 36)
 add_child(caption)
 var footer := BakeryTheme.text("Тёплая выпечка · Приятные встречи", 15, Color("#86728e"))
 footer.position = Vector2(605, 666)
 add_child(footer)
 column.modulate.a = 0
 create_tween().tween_property(column, "modulate:a", 1.0, 0.45)
func _adapt_menu():
 var scroll := find_child("MenuScroll",true,false) as ScrollContainer
 var actions := find_child("MenuActions",true,false) as VBoxContainer
 if scroll == null or actions == null: return
 var compact := scroll.size.y < 650.0
 actions.add_theme_constant_override("separation",6 if compact else 10)
 for button in actions.get_children():
  button.custom_minimum_size.y = 46 if compact else 52
func _menu_button_theme() -> Theme:
 var menu_theme := Theme.new()
 for state in ["normal","hover","pressed","disabled","focus"]:
  var color := Color("#b9ddd0")
  if state == "hover": color = Color("#9dcebd")
  elif state == "pressed": color = Color("#79ad9c")
  elif state == "disabled": color = Color("#dce5df")
  var style := BakeryTheme.panel(color,16)
  if state == "focus":
   style.bg_color = Color.TRANSPARENT
   style.shadow_size = 0
   style.border_color = Color("#76546e")
   style.set_border_width_all(2)
  menu_theme.set_stylebox(state,"Button",style)
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  menu_theme.set_color(state,"Button",Color("#58475f"))
 menu_theme.set_color("font_disabled_color","Button",Color("#928a92"))
 return menu_theme
func show_settings():
 var session: GameSessionManager = get_node("/root/GameSession")
 var audio: Node = get_node("/root/AudioHub")
 var overlay := ColorRect.new()
 overlay.color = Color(0.19,0.14,0.23,0.8)
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(overlay)
 var center := CenterContainer.new(); center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); overlay.add_child(center)
 var panel := PanelContainer.new(); panel.custom_minimum_size.x = 620; panel.add_theme_stylebox_override("panel",BakeryTheme.panel(Color("#fff8ed"),22)); center.add_child(panel)
 var column := VBoxContainer.new(); column.add_theme_constant_override("separation",10); panel.add_child(column)
 column.add_child(BakeryTheme.text("Настройки",28))
 _settings_slider(column,"Общая громкость",float(session.settings.get("master",1.0)),func(value):audio.set_master(value);session.save_settings())
 _settings_slider(column,"Музыка",float(audio.gains.Music),func(value):audio.set_gain("Music",value);session.save_settings())
 _settings_slider(column,"Звуковые эффекты",float(audio.gains.SFX),func(value):audio.set_gain("SFX",value);audio.set_gain("UI",value);session.save_settings())
 var fullscreen := CheckButton.new();fullscreen.text="Полный экран";fullscreen.button_pressed=bool(session.settings.get("fullscreen",false));column.add_child(fullscreen)
 fullscreen.toggled.connect(func(value):session.settings.fullscreen=value;session.apply_display_settings();session.save_settings())
 var resolution := OptionButton.new();column.add_child(BakeryTheme.text("Разрешение окна",16));column.add_child(resolution)
 var sizes: Array[Vector2i] = [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]
 for size in sizes:
  resolution.add_item("%d × %d" % [size.x,size.y])
  if size == session.settings.get("resolution",Vector2i(1280,720)): resolution.select(resolution.item_count-1)
 resolution.item_selected.connect(func(index):session.settings.resolution=sizes[index];session.apply_display_settings();session.save_settings())
 var back := Button.new();back.text="Назад";back.custom_minimum_size.y=44;column.add_child(back)
 back.pressed.connect(func():session.save_settings();overlay.queue_free())
func _settings_slider(parent: Node, title: String, value: float, changed: Callable):
 var row := HBoxContainer.new();parent.add_child(row)
 var label := BakeryTheme.text(title,17);label.custom_minimum_size.x=230;row.add_child(label)
 var slider := HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=0.01;slider.value=value;slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
 slider.value_changed.connect(changed)
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
