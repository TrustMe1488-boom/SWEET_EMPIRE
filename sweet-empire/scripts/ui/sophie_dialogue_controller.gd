class_name SophieDialogueController
extends PanelContainer
signal greeting_finished
signal visibility_requested(talking: bool)
var lines: Array[String] = []
var index: int = 0
var closable: bool = true
var requested_visible: bool = false
var text_label: Label
var next_button: Button
var close_button: Button
func _ready():
 add_theme_stylebox_override("panel", BakeryTheme.panel(Color("#fff8edf8"), 22))
 set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 anchor_left = 0.55
 offset_left = 16
 offset_right = -24
 offset_top = -214
 offset_bottom = -24
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 14)
 add_child(row)
 row.add_child(SophiePortrait.new())
 var column := VBoxContainer.new()
 column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_theme_constant_override("separation", 6)
 row.add_child(column)
 column.add_child(BakeryTheme.text("Софи · рядом с вами", 19, Color("#698c7d")))
 text_label = BakeryTheme.text("", 17)
 text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 text_label.custom_minimum_size.y = 80
 text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 column.add_child(text_label)
 var actions := HBoxContainer.new()
 column.add_child(actions)
 next_button = Button.new()
 next_button.text = "Продолжить"
 next_button.pressed.connect(advance)
 actions.add_child(next_button)
 close_button = Button.new()
 close_button.text = "Закрыть"
 close_button.pressed.connect(dismiss)
 actions.add_child(close_button)
 hide()
func present(content: Array[String], allow_close: bool):
 lines = content.duplicate()
 index = 0
 closable = allow_close
 close_button.visible = closable
 next_button.text = "Понятно" if closable and lines.size() == 1 else "Продолжить"
 text_label.text = lines[0] if not lines.is_empty() else ""
 requested_visible = true
 show()
 visibility_requested.emit(true)
func advance():
 if lines.is_empty(): return
 index += 1
 if index < lines.size(): text_label.text = lines[index]
 else:
  requested_visible = false
  hide()
  visibility_requested.emit(false)
  if not closable: greeting_finished.emit()
func dismiss():
 if not closable: return
 requested_visible = false
 hide()
 visibility_requested.emit(false)
