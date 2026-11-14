class_name ControlSettings
extends Control
var game:Node
var controls:GameInputManager
var bridge:GestureBridge
var shade:ColorRect
var status:Label
var python_path:LineEdit
var capture:Button
var previous_modal:StringName=&""
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS;mouse_filter=Control.MOUSE_FILTER_IGNORE;theme=BakeryTheme.create();set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade=ColorRect.new();shade.color=Color(0.2,0.15,0.24,0.8);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.add_child(center)
 var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(840,0);center.add_child(panel)
 var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
 column.add_child(BakeryTheme.text("Камера, калибровка и звук",25))
 status=BakeryTheme.text("Камера выключена. Клавиатура и мышь доступны.",16);status.custom_minimum_size.x=780;status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(status)
 python_path=LineEdit.new();python_path.text="python";python_path.placeholder_text="Путь к Python";column.add_child(python_path)
 var buttons:=HBoxContainer.new();column.add_child(buttons)
 var enable:=Button.new();enable.text="Включить камеру";enable.custom_minimum_size.y=44;buttons.add_child(enable);enable.pressed.connect(func():bridge.start(python_path.text))
 var disable:=Button.new();disable.text="Выключить";buttons.add_child(disable);disable.pressed.connect(bridge.stop)
 if OS.is_debug_build():
  var fake:=Button.new();fake.text="Отладка: искусственные команды без камеры";fake.custom_minimum_size.y=36;column.add_child(fake);fake.pressed.connect(func():bridge.start(python_path.text,0,true))
 capture=Button.new();capture.text="Зафиксировать центр";buttons.add_child(capture);capture.pressed.connect(func():
  if controls.calibrate():status.text="Центр зафиксирован. Отклоняй ладонь для движения. Указательный — курсор."
  else:status.text="Сначала покажи руку камере.")
 var again:=Button.new();again.text="Повторная калибровка";buttons.add_child(again);again.pressed.connect(func():controls.reset_calibration();status.text="Покажи ладонь и снова зафиксируй центр.")
 slider(column,"Чувствительность",0.5,3.0,controls.sensitivity,func(value):controls.sensitivity=value)
 slider(column,"Мёртвая зона",0.04,0.3,controls.deadzone,func(value):controls.deadzone=value)
 column.add_child(BakeryTheme.text("Ладонь — движение · короткий кулак — E · долгий — пауза\nУказательный — курсор · щипок и отпускание — нажатие",15))
 for bus in ["Music","SFX","UI","Ambient"]:
  slider(column,bus,0,1,float(get_node("/root/AudioHub").gains[bus]),func(value):get_node("/root/AudioHub").set_gain(bus,value))
 var close:=Button.new();close.text="Проверить движение / вернуться · Esc";close.custom_minimum_size.y=48;column.add_child(close);close.pressed.connect(func():game.set_paused(false);controls.clear_motion())
 bridge.packet.connect(controls.feed);bridge.status_changed.connect(func(text):status.text=text)
 controls.interact_requested.connect(func():
  if game.modal_kind==&"" and not get_tree().paused:game.interact())
 controls.pause_requested.connect(game.handle_escape)
 controls.cursor_moved.connect(move_cursor);controls.click_requested.connect(click_cursor)
 var settings_button:=Button.new();settings_button.text="Камера / Звук";settings_button.custom_minimum_size.y=46
 game.hud_view.pause_buttons[0].get_parent().add_child(settings_button);settings_button.pressed.connect(open)
 var cursor_layer:=CanvasLayer.new();cursor_layer.layer=20;game.add_child(cursor_layer)
 var cursor:Control=Control.new();cursor.set_script(preload("res://scripts/input/gesture_cursor.gd"));cursor.controls=controls;cursor_layer.add_child(cursor)
 shade.hide()
func slider(parent:Node,title:String,minimum:float,maximum:float,value:float,callback:Callable):
 var row:=HBoxContainer.new();parent.add_child(row)
 var label:=BakeryTheme.text(title,16);label.custom_minimum_size.x=200;row.add_child(label)
 var slide:=HSlider.new();slide.min_value=minimum;slide.max_value=maximum;slide.step=0.01;slide.value=value;slide.custom_minimum_size=Vector2(540,30);slide.value_changed.connect(callback);row.add_child(slide)
func open():
 game.set_paused(true);game.pause_panel.hide();game.modal_kind=&"settings";controls.clear_motion();shade.show()
func _process(_delta:float):
 if game.modal_kind!=&"settings":shade.hide()
 if game.modal_kind!=previous_modal:controls.clear_motion();previous_modal=game.modal_kind
 capture.disabled=not controls.tracked
 if game.dashboard!=null:
  game.dashboard.control_label.text=("Жесты · курсор" if controls.mode=="cursor" else "Жесты · ладонь") if controls.active_source=="gesture" and controls.tracked else "Клавиатура / мышь"
func move_cursor(position:Vector2):
 var event:=InputEventMouseMotion.new();event.position=get_viewport().get_final_transform()*(position*get_viewport().get_visible_rect().size);event.global_position=event.position;event.set_meta("gesture_generated",true);Input.parse_input_event(event)
func click_cursor(position:Vector2):
 move_cursor(position)
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new();event.position=get_viewport().get_final_transform()*(position*get_viewport().get_visible_rect().size);event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;event.set_meta("gesture_generated",true);Input.parse_input_event(event)
func _input(event:InputEvent):
 if event.has_meta("gesture_generated"):return
 if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):controls.keyboard_action()
