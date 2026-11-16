class_name SophiePortrait
extends Control
func _ready():
 custom_minimum_size = Vector2(84, 100)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
 draw_circle(Vector2(42, 43), 36, Color("#556359"))
 draw_circle(Vector2(12, 50), 11, Color("#556359"))
 draw_circle(Vector2(72, 50), 11, Color("#556359"))
 draw_circle(Vector2(42, 47), 28, Color("#edc1a0"))
 for x in [30, 54]:
  draw_circle(Vector2(x, 44), 6, Color("#fff8ed"))
  draw_circle(Vector2(x, 45), 4, Color("#58475f"))
  draw_circle(Vector2(x - 1, 43), 1.4, Color.WHITE)
 for x in [22, 62]: draw_circle(Vector2(x, 55), 4, Color("#e6a2a0"))
 for x in [25, 42, 57]: draw_circle(Vector2(x, 20), 11, Color("#556359"))
 draw_arc(Vector2(42, 54), 9, 0.2, PI - 0.2, 12, Color("#925e60"), 2, true)
 draw_circle(Vector2(69, 28), 7, Color("#f3c5d5"))
 draw_style_box(BakeryTheme.panel(Color("#b9ddd0"), 12), Rect2(12, 76, 60, 24))
