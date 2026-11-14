class_name ManagementMenu
extends Control
signal close_requested
var development: DevelopmentManager
var personnel: PersonnelManager
var economy: EconomySystem
var mode: StringName = &"development"
var title: Label
var balance: Label
var message: Label
var row: HBoxContainer
var action_buttons: Dictionary = {}
var close_button: Button
var checkout_upgrades:CheckoutUpgradeManager
var checkout_label:Label
var checkout_button:Button
var tray_upgrades: TrayUpgradeManager
var tray_label: Label
var tray_button: Button
func _ready():
 theme = BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade := ColorRect.new()
 shade.color = Color(0.19, 0.14, 0.23, 0.75)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(1050, 0)
 panel.add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#fff8ed"), 24))
 center.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 14)
 panel.add_child(column)
 title = BakeryTheme.text("", 30)
 column.add_child(title)
 balance = BakeryTheme.text("", 18)
 column.add_child(balance)
 row = HBoxContainer.new()
 row.add_theme_constant_override("separation", 12)
 column.add_child(row)
 var tray_row := HBoxContainer.new()
 column.add_child(tray_row)
 tray_label = BakeryTheme.text("", 17)
 tray_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 tray_row.add_child(tray_label)
 tray_button = Button.new()
 tray_button.custom_minimum_size = Vector2(270, 44)
 tray_row.add_child(tray_button)
 var checkout_row:=HBoxContainer.new();column.add_child(checkout_row)
 checkout_label=BakeryTheme.text("",17);checkout_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;checkout_row.add_child(checkout_label)
 checkout_button=Button.new();checkout_button.custom_minimum_size=Vector2(270,44);checkout_row.add_child(checkout_button)
 message = BakeryTheme.text("", 16, Color("#89708c"))
 column.add_child(message)
 var close := Button.new()
 close_button = close
 close.text = "Закрыть · Esc"
 close.custom_minimum_size.y = 46
 close.pressed.connect(func(): close_requested.emit())
 column.add_child(close)
 hide()
func open_menu(value: StringName):
 mode = value
 message.text = "Игра приостановлена. Доставка остаётся за Мией."
 refresh()
 show()
 close_button.grab_focus()
 for button in action_buttons.values():
  if not button.disabled:
   button.grab_focus()
   break
func refresh():
 if row == null: return
 title.text = "Развитие кондитерской" if mode == &"development" else "Персонал кондитерской"
 var employed: int = 0
 for workplace in personnel.workplaces():
  if workplace.employed: employed += 1
 balance.text = "Баланс: %d монет   ·   Повара: %d / %d   ·   Покупка станции не включает найм" % [economy.coins, employed, development.stations.size()]
 for child in row.get_children():
  row.remove_child(child)
  child.queue_free()
 action_buttons.clear()
 for product in ProductCatalog.all(): build_card(product)
 checkout_label.get_parent().visible=mode==&"development" and checkout_upgrades!=null
 if checkout_upgrades!=null:
  var captured_checkout:=checkout_upgrades.level
  checkout_label.text="Касса · уровень %d/3 · лимиты %d / %d / %d / %d"%[captured_checkout,checkout_upgrades.checkout.limit_for(&"COOKIE"),checkout_upgrades.checkout.limit_for(&"COFFEE"),checkout_upgrades.checkout.limit_for(&"CUPCAKE"),checkout_upgrades.checkout.limit_for(&"CAKE")]
  for connection in checkout_button.pressed.get_connections():checkout_button.pressed.disconnect(connection.callable)
  checkout_button.text="Улучшить кассу · %d"%CheckoutUpgradeManager.COSTS[captured_checkout-1] if captured_checkout<3 else "Касса улучшена полностью"
  checkout_button.disabled=captured_checkout>=3 or (captured_checkout<3 and not economy.can_afford(CheckoutUpgradeManager.COSTS[captured_checkout-1])) or (checkout_upgrades.allowed.is_valid() and not checkout_upgrades.allowed.call())
  checkout_button.pressed.connect(func():checkout_upgrades.upgrade(captured_checkout);refresh())
 tray_label.get_parent().visible = mode == &"development" and tray_upgrades != null
 if tray_upgrades != null:
  var captured := tray_upgrades.level
  tray_label.text = "Поднос · уровень %d / 3 · вместимость %d" % [captured, tray_upgrades.tray.capacity]
  for connection in tray_button.pressed.get_connections(): tray_button.pressed.disconnect(connection.callable)
  tray_button.text = "Улучшить поднос · %d" % TrayUpgradeManager.COSTS[captured - 1] if captured < 3 else "Поднос улучшен полностью"
  tray_button.disabled = captured >= 3 or (captured < 3 and not economy.can_afford(TrayUpgradeManager.COSTS[captured - 1])) or (tray_upgrades.allowed.is_valid() and not tray_upgrades.allowed.call())
  tray_button.pressed.connect(func():
   tray_upgrades.upgrade(captured)
   refresh())
func build_card(product: ProductDefinition):
 var station := development.get_station(product.id)
 var card := PanelContainer.new()
 card.custom_minimum_size = Vector2(244, 0)
 card.add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#f6edea"), 16))
 row.add_child(card)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 10)
 card.add_child(column)
 var icon := HudIcon.new()
 icon.kind = product.icon_kind
 column.add_child(icon)
 column.add_child(BakeryTheme.text(product.station_name, 18))
 var description := "Продажа: %d монет\nБазовое время: %.0f с\nЗапас: до 5 шт." % [product.sale_price, product.base_time]
 if station != null:
  description += "\nУровень: %d / 5\nСейчас: %.2f с / шт.\nПовар: %s" % [station.level, station.production_time(), "работает" if station.has_cook else "не нанят"]
 else: description += "\nЗона: %d\nСтатус: не куплено\nПовар: после покупки" % product.zone
 column.add_child(BakeryTheme.text(description, 16))
 var action := Button.new()
 action.custom_minimum_size.y = 48
 action.add_theme_font_size_override("font_size", 16)
 column.add_child(action)
 action_buttons[product.id] = action
 var blocker := ""
 if mode == &"personnel":
  blocker = personnel.hire_blocker(product.id)
  action.text = "Нанять · %d" % product.hire_cost
  if station != null and station.has_cook: action.text = "Повар работает"
  action.pressed.connect(func():
   var result := personnel.hire(product.id)
   message.text = "Повар приступил к работе" if result else personnel.last_error
   refresh())
 elif station == null:
  blocker = development.purchase_blocker(product.id)
  action.text = "Купить · %d" % product.purchase_cost
  action.pressed.connect(func():
   var result := development.buy(product.id)
   message.text = "Оборудование установлено. Нанять повара: меню 2" if result else development.last_error
   refresh())
 else:
  var captured_level := station.level
  var cost := product.upgrade_cost(captured_level)
  action.text = "Улучшить · %d" % cost if captured_level < 5 else "Максимум · ур. 5"
  blocker = "Максимальный уровень" if captured_level >= 5 else ("Недостаточно монет" if not economy.can_afford(cost) else "")
  action.pressed.connect(func():
   var result := development.upgrade(product.id, captured_level)
   message.text = "Скорость производства увеличена" if result else development.last_error
   refresh())
 if development.operation_allowed.is_valid() and not development.operation_allowed.call(): blocker = "Завершите обучение или испытание"
 action.disabled = not blocker.is_empty()
 action.tooltip_text = blocker
 var note := BakeryTheme.text(blocker if not blocker.is_empty() else ("Без зарплаты" if mode == &"personnel" else "Одна станция на товар"), 13, Color("#92768f"))
 note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 note.custom_minimum_size = Vector2(205, 38)
 column.add_child(note)
