extends Control
signal main_menu_requested
signal continue_requested
var summary: Label
func _ready():
 theme = BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade := ColorRect.new()
 shade.color = Color("#ded6e5")
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(730, 0)
 center.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 22)
 panel.add_child(column)
 column.add_child(BakeryTheme.text("SWEET EMPIRE", 46, Color("#886781")))
 column.add_child(BakeryTheme.text("Поздравляем, Мия!", 36))
 column.add_child(BakeryTheme.text("Вы создали свою сладкую империю.", 23))
 summary = BakeryTheme.text("Кампания завершена", 21)
 column.add_child(summary)
 var button := Button.new()
 button.text = "Продолжить в бесконечном режиме"
 button.custom_minimum_size.y = 60
 button.pressed.connect(func(): continue_requested.emit())
 column.add_child(button)
 button.grab_focus()
 var menu:=Button.new()
 menu.text="Главное меню"
 menu.custom_minimum_size.y=48
 menu.pressed.connect(func():main_menu_requested.emit())
 column.add_child(menu)
func set_results(stats: ProgressTracker, gems: int, coin_rewards: int, awards: int):
 summary.text = "Покупателей обслужено: %d\nОбщий заработок продажами: %d монет\nИтоговый рейтинг: %.2f\nНаграды: %d монет и %d кристаллов\nПолучено наград: %d" % [int(stats.amount("served")), int(stats.amount("sales_income")), stats.amount("rating"), coin_rewards, gems, awards]
