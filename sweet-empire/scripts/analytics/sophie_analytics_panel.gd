class_name SophieAnalyticsPanel
extends Control
var compact_entry:bool=true
var game: Node
var launch: Button
var shade: ColorRect
var column: VBoxContainer
func _ready():
 process_mode = Node.PROCESS_MODE_ALWAYS
 theme = BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 launch = Button.new()
 launch.text = "Софи · Аналитика"
 launch.position = Vector2(24, 225)
 launch.pressed.connect(open)
 add_child(launch)
 shade = ColorRect.new()
 shade.color = Color(0.19,0.14,0.23,0.78)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(880,0)
 center.add_child(panel)
 column = VBoxContainer.new()
 column.add_theme_constant_override("separation",10)
 panel.add_child(column)
 shade.hide()
func _process(_delta: float):
 launch.visible = compact_entry and game.modal_kind == &"" and (game.progression == null or game.progression.tutorial.done)
 if game.modal_kind != &"analytics": shade.hide()
func open():
 if game.progression != null:
  game.campaign_view.show_journal("analytics")
  return
 game.set_paused(true)
 game.pause_panel.hide()
 game.modal_kind = &"analytics"
 for child in column.get_children():
  column.remove_child(child)
  child.queue_free()
 column.add_child(BakeryTheme.text("Софи · спрос на ближайшие 2 минуты",26))
 column.add_child(BakeryTheme.text("%s · обновлено на %.1f с" % [game.predictor.source,game.predictor.last_update],18))
 for i in 4:
  column.add_child(BakeryTheme.text("%s: ~%d заказов" % [ProductCatalog.all()[i].display_name,roundi(game.predictor.forecast[i])],20))
 column.add_child(BakeryTheme.text("Предупреждение по правилам (не ML):",18))
 column.add_child(BakeryTheme.text(game.advisor.advise(game),18))
 var close := Button.new()
 close.text = "Продолжить · Esc"
 close.pressed.connect(func(): game.set_paused(false);shade.hide())
 column.add_child(close)
 shade.show()
