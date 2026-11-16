class_name HudIcon
extends Control
var kind: String = "coin"
var color: Color = Color("#d8a477")
func _ready():
 custom_minimum_size = Vector2(34, 34)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
 var at := Vector2(17, 17)
 match kind:
  "coin":
   draw_circle(at, 12, Color("#dfb572"))
   draw_arc(at, 8, 0, TAU, 24, Color("#fff2de"), 2, true)
   draw_line(Vector2(17, 11), Vector2(17, 23), Color("#a97c51"), 3, true)
  "star":
   var points := PackedVector2Array()
   for i in 10:
    var angle := i * PI / 5 - PI / 2
    points.append(at + Vector2(cos(angle), sin(angle)) * (13 if i % 2 == 0 else 6))
   draw_colored_polygon(points, Color("#d8a477"))
  "tray":
   draw_style_box(BakeryTheme.panel(Color("#bba6d7"), 4), Rect2(3, 16, 28, 12))
   for x in [10, 24]:
    draw_circle(Vector2(x, 14), 6, Color("#d8a477"))
    draw_circle(Vector2(x - 1, 12), 1.4, Color("#79533f"))
  "queue":
   for x in [8, 25]:
    draw_circle(Vector2(x, 10), 5, color)
    draw_line(Vector2(x, 20), Vector2(x, 28), color, 9, true)
  "cookie":
   draw_circle(at, 12, Color("#d8a477"))
   for point in [Vector2(12, 12), Vector2(22, 13), Vector2(15, 23), Vector2(23, 22)]: draw_circle(point, 2, Color("#79533f"))

  "coffee":
   draw_style_box(BakeryTheme.panel(Color("#b9ddd0"), 3), Rect2(8, 10, 19, 19))
   draw_line(Vector2(6, 9), Vector2(29, 9), Color("#79533f"), 4, true)
   draw_line(Vector2(13, 4), Vector2(13, 1), Color("#d8a477"), 2, true)
   draw_line(Vector2(22, 4), Vector2(22, 1), Color("#d8a477"), 2, true)
  "cupcake":
   draw_style_box(BakeryTheme.panel(Color("#bba6d7"), 3), Rect2(8, 18, 20, 13))
   draw_circle(Vector2(13, 16), 7, Color("#f3c5d5"))
   draw_circle(Vector2(23, 16), 7, Color("#f3c5d5"))
   draw_circle(Vector2(18, 10), 7, Color("#f3c5d5"))
   draw_circle(Vector2(18, 3), 3, Color("#bc7189"))
  "cake":
   draw_style_box(BakeryTheme.panel(Color("#d8a477"), 3), Rect2(4, 12, 28, 19))
   draw_line(Vector2(5, 22), Vector2(31, 22), Color("#f3c5d5"), 4, true)
   draw_line(Vector2(5, 12), Vector2(31, 12), Color("#fff2de"), 5, true)
   for x in [11, 25]: draw_circle(Vector2(x, 8), 3, Color("#bc7189"))
