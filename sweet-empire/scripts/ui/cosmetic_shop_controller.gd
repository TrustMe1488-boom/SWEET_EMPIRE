class_name CosmeticShopController
extends Control
var manager: CosmeticManager
var preview: CosmeticPreviewController
var viewport: SubViewport
var selected: CosmeticDefinition
var category: String="MIA_OUTFIT"
var balance_label: Label
var title_label: Label
var description_label: Label
var price_label: Label
var state_label: Label
var action: Button
var item_column: VBoxContainer
var category_buttons: Dictionary={}
var message: Label
var back_button: Button
func _ready():
 manager=get_node("/root/GameSession").cosmetics
 theme=BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var background:=ColorRect.new();background.color=Color("#DED6E5")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
 var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 add_child(margin)
 var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",16);margin.add_child(outer)
 var header:=HBoxContainer.new();outer.add_child(header)
 var title:=BakeryTheme.text("SWEET EMPIRE · МАГАЗИН",30)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(title)
 balance_label=BakeryTheme.text("",23,Color("#9475AA"));header.add_child(balance_label)
 var body:=HBoxContainer.new();body.add_theme_constant_override("separation",18)
 body.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(body)
 var left:=PanelContainer.new();left.custom_minimum_size.x=260;body.add_child(left)
 var left_column:=VBoxContainer.new();left_column.add_theme_constant_override("separation",12);left.add_child(left_column)
 left_column.add_child(BakeryTheme.text("КОЛЛЕКЦИИ",16))
 var captions:={"MIA_OUTFIT":"Форма Мии","INTERIOR_THEME":"Интерьер","DESSERT_STYLE":"Десерты"}
 for key in CosmeticCatalog.CATEGORIES:
  var button:=Button.new();button.text=captions[key];button.custom_minimum_size.y=44
  button.add_theme_font_size_override("font_size",18)
  button.pressed.connect(select_category.bind(key))
  left_column.add_child(button);category_buttons[key]=button
 left_column.add_child(HSeparator.new())
 var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 left_column.add_child(scroll)
 item_column=VBoxContainer.new();item_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 item_column.add_theme_constant_override("separation",12);scroll.add_child(item_column)
 var center:=PanelContainer.new();center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 center.size_flags_stretch_ratio=1.0;body.add_child(center)
 var center_column:=VBoxContainer.new();center.add_child(center_column)
 center_column.add_child(BakeryTheme.text("Примерь настроение",21))
 var container:=SubViewportContainer.new();container.stretch=true
 container.size_flags_horizontal=Control.SIZE_EXPAND_FILL;container.size_flags_vertical=Control.SIZE_EXPAND_FILL
 container.custom_minimum_size=Vector2(360,300);center_column.add_child(container)
 viewport=SubViewport.new();viewport.size=Vector2i(560,520)
 viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 container.add_child(viewport)
 preview=CosmeticPreviewController.new();viewport.add_child(preview)
 var hint:=BakeryTheme.text("3D-предпросмотр · покупки не совершаются",13,Color("#8D788D"))
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;center_column.add_child(hint)
 var right:=PanelContainer.new();right.custom_minimum_size.x=300;body.add_child(right)
 var details:=VBoxContainer.new();details.add_theme_constant_override("separation",18);right.add_child(details)
 title_label=BakeryTheme.text("",27);title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 title_label.custom_minimum_size.x=250;details.add_child(title_label)
 description_label=BakeryTheme.text("",18);description_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 description_label.custom_minimum_size.x=250;details.add_child(description_label)
 details.add_child(HSeparator.new())
 price_label=BakeryTheme.text("",23,Color("#9475AA"));details.add_child(price_label)
 state_label=BakeryTheme.text("",18);details.add_child(state_label)
 action=Button.new();action.custom_minimum_size.y=56;action.pressed.connect(perform_action)
 details.add_child(action);BakeryTheme.animate_button(action)
 message=BakeryTheme.text("",16,Color("#96717D"));message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 message.custom_minimum_size.x=250;details.add_child(message)
 var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;details.add_child(spacer)
 var note:=BakeryTheme.text("Только внешний вид.
Характеристики не меняются.",15,Color("#8D788D"));details.add_child(note)
 var footer:=HBoxContainer.new();outer.add_child(footer)
 back_button=Button.new();back_button.text="← Главное меню";back_button.custom_minimum_size=Vector2(250,48)
 back_button.pressed.connect(back);footer.add_child(back_button)
 var tip:=BakeryTheme.text("Кристаллы зарабатываются в кампании. Примерка бесплатна.",16)
 tip.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;footer.add_child(tip)
 manager.changed.connect(refresh)
 manager.wallet.changed.connect(refresh)
 select_category(category)
 back_button.grab_focus()
func select_category(value: String):
 category=value
 for child in item_column.get_children():item_column.remove_child(child);child.queue_free()
 for key in category_buttons:category_buttons[key].disabled=key==category
 for item in CosmeticCatalog.in_category(category):
  var button:=Button.new();button.text=item.display_name.replace(" ","\n")+"
"+("Бесплатно" if item.is_free else "%d кристаллов"%item.price)
  button.custom_minimum_size=Vector2(215,84);button.add_theme_font_size_override("font_size",15)
  button.pressed.connect(select_item.bind(item.id));item_column.add_child(button)
 var current:=manager.active(category)
 select_item(current.id)
func select_item(id: StringName):
 selected=CosmeticCatalog.find(id)
 if selected==null:return
 preview.show_item(selected)
 message.text=""
 refresh()
func refresh():
 if selected==null:return
 balance_label.text="◆ %d кристаллов"%manager.wallet.balance
 title_label.text=selected.display_name
 description_label.text=selected.description
 price_label.text="Бесплатно" if selected.is_free else "◆ %d кристаллов"%selected.price
 var status:=manager.status(selected.id)
 state_label.text=["Не приобретено","В коллекции","Применено"][status]
 action.text=["Купить","Применить","Уже применено"][status]
 action.disabled=status==CosmeticManager.Status.EQUIPPED
 if status==CosmeticManager.Status.LOCKED:
  var reason:=manager.purchase_blocker(selected.id)
  action.disabled=not reason.is_empty()
  message.text=reason
 elif message.text==manager.last_error:message.text=""
func perform_action():
 if selected==null:return
 if manager.owns(selected.id):
  manager.equip(selected.id)
  message.text="Оформление применено. Продолжи игру из главного меню."
 else:
  if manager.purchase(selected.id):message.text="Предмет в коллекции! Теперь его можно применить."
  else:message.text=manager.last_error
 refresh()
func back():
 preview.end_preview()
 get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
func _unhandled_input(event: InputEvent):
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();back()
