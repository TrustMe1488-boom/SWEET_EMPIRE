extends Control
var controls:GameInputManager
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS;mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(_delta:float):queue_redraw()
func _draw():
 if controls==null or not controls.tracked or controls.mode!="cursor" or controls.active_source!="gesture":return
 var point:Vector2=controls.cursor*size
 draw_circle(point,13,Color("#FFF2DE"));draw_arc(point,16,0,TAU,24,Color("#A481B5"),3);draw_circle(point,4,Color("#A481B5"))
