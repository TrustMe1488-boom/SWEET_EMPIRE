class_name ShopMenuButton
extends BaseButton
# A drawn BaseButton keeps the existing menu Button API intact while providing
# a large, keyboard-accessible illustrated entry to the new shop section.
func _ready():
 custom_minimum_size=Vector2(390,56)
 focus_mode=Control.FOCUS_ALL
 mouse_entered.connect(queue_redraw)
 mouse_exited.connect(queue_redraw)
 button_down.connect(queue_redraw)
 button_up.connect(queue_redraw)
 focus_entered.connect(queue_redraw)
 focus_exited.connect(queue_redraw)
func _draw():
 var color:=Color("#DDEBE4") if not is_hovered() else Color("#CBE2D6")
 if is_pressed():color=color.darkened(0.07)
 var box:=BakeryTheme.panel(color)
 box.draw(get_canvas_item(),Rect2(Vector2.ZERO,size))
 var font:=ThemeDB.fallback_font
 var title:="Магазин"
 var width:=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
 draw_string(font,Vector2((size.x-width)/2,36),title,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("#65516B"))
 if has_focus():draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color("#9B84A4"),false,2)
