class_name BakeryTheme
extends RefCounted
const INK = Color("#58475f")
static func panel(color: Color = Color("#fff8ed"), radius: int = 18) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(radius)
 style.content_margin_left = 18
 style.content_margin_right = 18
 style.content_margin_top = 12
 style.content_margin_bottom = 12
 style.border_color = Color("#e6d6d3")
 style.set_border_width_all(1)
 style.shadow_color = Color(0.27, 0.2, 0.3, 0.09)
 style.shadow_size = 4
 style.shadow_offset = Vector2(0, 3)
 return style
static func create() -> Theme:
 var theme := Theme.new()
 theme.default_font_size = 20
 theme.set_color("font_color", "Label", INK)
 theme.set_stylebox("panel", "PanelContainer", panel())
 for state in ["normal", "hover", "pressed", "focus", "disabled"]:
  var color: Color = Color("#b9ddd0")
  if state == "disabled": color = Color("#e8e0dc")
  if state == "hover": color = Color("#cbe8dd")
  if state == "pressed": color = Color("#edb8cc")
  var style := panel(color, 16)
  if state == "focus":
   style.bg_color = Color.TRANSPARENT
   style.shadow_size = 0
   style.border_color = Color("#9477af")
   style.set_border_width_all(2)
  theme.set_stylebox(state, "Button", style)
 for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
  theme.set_color(state, "Button", INK)
 theme.set_color("font_disabled_color", "Button", Color("#78677c"))
 return theme
static func animate_button(button: Button):
 button.mouse_entered.connect(func():
  var tween := button.create_tween()
  tween.tween_property(button, "modulate", Color(1.04, 1.04, 1.04), 0.15))
 button.mouse_exited.connect(func():
  var tween := button.create_tween()
  tween.tween_property(button, "modulate", Color.WHITE, 0.15))
static func text(value: String, size: int = 20, color: Color = INK) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_color", color)
 return label
