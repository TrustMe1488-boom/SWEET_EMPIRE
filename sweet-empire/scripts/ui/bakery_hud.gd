class_name BakeryHUD
extends Control
signal development_requested
signal personnel_requested
var stations_label: Label
var stock_label: Label
var tray_details: Label
var brand: Label
var labels: Dictionary = {}
var cards: Dictionary = {}
var values: Dictionary = {}
var pulses: Dictionary = {}
var context: PanelContainer
var context_label: Label
var pause_panel: ColorRect
var pause_buttons: Array[Button] = []
var order_icon: HudIcon
var tray_bar: ProgressBar
var context_target: int = -1
func _ready():
 theme = BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 brand = BakeryTheme.text("SWEET EMPIRE   /   КОНДИТЕРСКАЯ МИИ", 13, Color("#786781"))
 brand.position = Vector2(24, 7)
 add_child(brand)
 var row := HBoxContainer.new()
 row.position = Vector2(24, 28)
 row.add_theme_constant_override("separation", 10)
 add_child(row)
 var titles := ["Монеты", "Рейтинг", "Поднос", "Очередь", "Первый заказ"]
 var kinds := ["coin", "star", "tray", "queue", "cookie"]
 for i in titles.size():
  var card := PanelContainer.new()
  card.custom_minimum_size = Vector2(148 if i < 4 else 197, 60)
  var card_style := BakeryTheme.panel()
  card_style.content_margin_top = 8
  card_style.content_margin_bottom = 8
  card.add_theme_stylebox_override("panel", card_style)
  row.add_child(card)
  cards[kinds[i]] = card
  var content := HBoxContainer.new()
  content.add_theme_constant_override("separation", 10)
  card.add_child(content)
  var icon := HudIcon.new()
  icon.kind = kinds[i]
  if kinds[i] == "cookie": order_icon = icon
  content.add_child(icon)
  var column := VBoxContainer.new()
  column.add_theme_constant_override("separation", 0)
  content.add_child(column)
  column.add_child(BakeryTheme.text(titles[i], 12, Color("#87768b")))
  var label := BakeryTheme.text("—", 20)
  column.add_child(label)
  labels[kinds[i]] = label
  if kinds[i] == "tray":
   tray_bar = ProgressBar.new()
   tray_bar.custom_minimum_size = Vector2(65, 4)
   tray_bar.max_value = 5
   tray_bar.show_percentage = false
   var track := StyleBoxFlat.new()
   track.bg_color = Color("#eee5ee")
   track.set_corner_radius_all(2)
   var fill := StyleBoxFlat.new()
   fill.bg_color = Color("#bba6d7")
   fill.set_corner_radius_all(2)
   tray_bar.add_theme_stylebox_override("background", track)
   tray_bar.add_theme_stylebox_override("fill", fill)
   column.add_child(tray_bar)
 var guide := BakeryTheme.text("WASD  движение   ·   Esc  пауза", 15, Color("#786781"))
 guide.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 guide.offset_left = 24
 guide.offset_top = -34
 guide.offset_right = 430
 guide.offset_bottom = -10
 add_child(guide)
 context = PanelContainer.new()
 context.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
 context.offset_left = -190
 context.offset_right = 190
 context.offset_top = -91
 context.offset_bottom = -30
 context.add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#fff8edf5")))
 add_child(context)
 var context_row := HBoxContainer.new()
 context_row.add_theme_constant_override("separation", 15)
 context.add_child(context_row)
 var key := PanelContainer.new()
 key.add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#b9ddd0"), 10))
 key.add_child(BakeryTheme.text("E", 24))
 context_row.add_child(key)
 context_label = BakeryTheme.text("", 20)
 context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 context_row.add_child(context_label)
 context.hide()
 stations_label = BakeryTheme.text("", 13)
 stations_label.position = Vector2(24, 96)
 add_child(stations_label)
 stock_label = BakeryTheme.text("", 13)
 stock_label.position = Vector2(24, 116)
 add_child(stock_label)
 tray_details = BakeryTheme.text("", 13)
 tray_details.position = Vector2(24, 136)
 add_child(tray_details)
 for i in 2:
  var button := Button.new()
  button.position = Vector2(900 + i * 174, 28)
  button.custom_minimum_size = Vector2(160, 46)
  button.text = ["1 · Развитие", "2 · Персонал"][i]
  button.add_theme_font_size_override("font_size", 16)
  add_child(button)
  if i == 0: button.pressed.connect(func(): development_requested.emit())
  else: button.pressed.connect(func(): personnel_requested.emit())
 build_pause()
func build_pause():
 pause_panel = ColorRect.new()
 pause_panel.color = Color(0.19, 0.14, 0.23, 0.7)
 pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(pause_panel)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 pause_panel.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(420, 0)
 panel.add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#fff8ed"), 26))
 center.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 panel.add_child(column)
 var title := BakeryTheme.text("Небольшой перерыв", 30)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(title)
 var subtitle := BakeryTheme.text("Кондитерская подождёт", 17, Color("#92809a"))
 subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 column.add_child(subtitle)
 var spacer := Control.new()
 spacer.custom_minimum_size.y = 8
 column.add_child(spacer)
 for caption in ["Продолжить", "Главное меню", "Выход"]:
  var button := Button.new()
  button.text = caption
  button.custom_minimum_size = Vector2(360, 52)
  column.add_child(button)
  BakeryTheme.animate_button(button)
  pause_buttons.append(button)
 pause_panel.hide()
func refresh(coins: int, rating: float, tray: int, count: int, has_order: bool, order_id: StringName = &"COOKIE", stations_text: String = "", tray_items: Dictionary = {}, checkout_items: Dictionary = {}, tray_capacity: int = 5):
 var updated := {"coin": str(coins), "star": "%.2f" % rating, "tray": "%d / %d" % [tray, tray_capacity], "queue": "%d / 5" % count, "cookie": ProductCatalog.find(order_id).display_name if has_order else "Ждём гостей"}
 for key in updated:
  if values.get(key, "") == updated[key]: continue
  values[key] = updated[key]
  labels[key].text = updated[key]
  if pulses.has(key) and pulses[key].is_valid(): pulses[key].kill()
  var card: PanelContainer = cards[key]
  var tween := create_tween()
  pulses[key] = tween
  card.modulate = Color("#e6cce4")
  tween.tween_property(card, "modulate", Color.WHITE, 0.45)
 var order_product := ProductCatalog.find(order_id)
 order_icon.kind = order_product.icon_kind if has_order else "cookie"
 order_icon.queue_redraw()
 if has_order: labels["cookie"].tooltip_text = "1 × " + order_product.display_name
 stations_label.text = stations_text
 stock_label.text = "Касса: " + describe_items(checkout_items)
 tray_details.text = "Поднос: " + describe_items(tray_items)
 tray_bar.max_value = tray_capacity
 tray_bar.value = tray
 labels["tray"].add_theme_color_override("font_color", Color("#99769e") if tray == tray_capacity else BakeryTheme.INK)
func show_context(target: int, message: String):
 context_label.text = message
 context.visible = target != 0
 if target != context_target and target != 0:
  context.modulate.a = 0
  create_tween().tween_property(context, "modulate:a", 1.0, 0.16)
 context_target = target

func describe_items(items: Dictionary) -> String:
 var parts: PackedStringArray = []
 for product in ProductCatalog.all():
  var amount: int = items.get(product.id, 0)
  if amount > 0: parts.append("%s × %d" % [product.display_name, amount])
 return " · ".join(parts) if not parts.is_empty() else "пусто"
