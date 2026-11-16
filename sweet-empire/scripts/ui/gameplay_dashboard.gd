class_name GameplayDashboard
extends Control
var game:Node
var panel:PanelContainer
var content:VBoxContainer
var stock:Label
var forecast:Label
var finances:Label
var warning:Label
var crystals:Label
var repeat_label:Label
var control_label:Label
var action_bar: HBoxContainer
var folded:bool=false
var last_warning:String=""
var elapsed:float=0
var _indicators:Dictionary={}
func _ready():
 process_mode=Node.PROCESS_MODE_ALWAYS;theme=BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.hud_view.guide.hide()
 game.hud_view.stations_label.hide();game.hud_view.stock_label.hide();game.hud_view.tray_details.hide()
 for child in game.hud_view.get_children():
  if child is Button and (child.text.contains("Развитие") or child.text.contains("Персонал")):child.hide()
 panel=PanelContainer.new();panel.position=Vector2(24,98);panel.custom_minimum_size.x=258;add_child(panel)
 var column:=VBoxContainer.new();panel.add_child(column)
 var fold:=Button.new();fold.text="Софи · свернуть / развернуть";fold.add_theme_font_size_override("font_size",13)
 fold.pressed.connect(func():folded=not folded;content.visible=not folded;panel.call_deferred("reset_size"));column.add_child(fold)
 warning=BakeryTheme.text("",14);warning.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;warning.custom_minimum_size.x=220;column.add_child(warning)
 content=VBoxContainer.new();column.add_child(content)
 stock=BakeryTheme.text("",13);content.add_child(stock)
 finances=BakeryTheme.text("",13);content.add_child(finances)
 forecast=BakeryTheme.text("",13);content.add_child(forecast)
 repeat_label=BakeryTheme.text("",13);content.add_child(repeat_label)
 crystals=BakeryTheme.text("",18);crystals.position=Vector2(900,30);add_child(crystals)
 control_label=BakeryTheme.text("WASD / мышь",14);control_label.position=Vector2(900,57);add_child(control_label)
 var bar:=HBoxContainer.new();action_bar=bar;bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
 bar.offset_left=24;bar.offset_right=-24;bar.offset_top=-68;bar.offset_bottom=-16;bar.add_theme_constant_override("separation",10);add_child(bar)
 for title in ["1 · Развитие","2 · Персонал","Аналитика","Пауза"]:
  var button:=Button.new();button.text=title;button.custom_minimum_size.y=52;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.add_theme_font_size_override("font_size",16);bar.add_child(button)
  match title:
   "1 · Развитие":button.pressed.connect(func():game.toggle_management(&"development"))
   "2 · Персонал":button.pressed.connect(func():game.toggle_management(&"personnel"))
   "Аналитика":button.pressed.connect(game.open_analytics)
   "Пауза":button.pressed.connect(game.handle_escape)
 if game.campaign_view!=null:
  game.campaign_view.dialogue.visibility_changed.connect(_update_action_bar)
 _update_action_bar()
 game.events.occurred.connect(func(_kind,_data):refresh())
 game.checkout.changed.connect(refresh);game.tray.changed.connect(refresh);game.queue.changed.connect(refresh);game.predictor.updated.connect(refresh)
 if game.progression!=null:
  game.progression.repeatable.changed.connect(refresh)
  game.progression.crystals.changed.connect(refresh)
 game.development.station_purchased.connect(register_indicator)
 for station in game.development.stations.values():register_indicator(station)
 refresh()
func _update_action_bar():
 if action_bar == null:return
 action_bar.visible = game.campaign_view == null or not game.campaign_view.dialogue.visible
func register_indicator(station:ProductionStation):
 if _indicators.has(station.product.id):return
 var indicator:=StationIndicator.new();indicator.station=station;indicator.mia=game.mia;game.add_child(indicator);_indicators[station.product.id]=indicator
 game.station_labels[station.product.id].hide()
func _process(delta:float):
 elapsed+=delta
 if elapsed>0.5 and game.modal_kind==&"":elapsed=0;refresh()
 visible=game.modal_kind==&""
 var talking: bool = game.campaign_view != null and game.campaign_view.dialogue.visible
 game.hud_view.set_context_suppressed(game.modal_kind != &"" or talking)
 if action_bar.visible and visible:
  var hud_bottom: float = game.hud_view.get_global_rect().end.y
  var bar_top: float = action_bar.get_global_rect().position.y
  var clearance: float = maxf(0.0, hud_bottom - bar_top) + 12.0
  game.hud_view.context.offset_bottom = -clearance
  game.hud_view.context.offset_top = -clearance - maxf(54.0, game.hud_view.context.get_combined_minimum_size().y)
 if game.campaign_view!=null:game.campaign_view.gems_label.hide()
func refresh():
 if game.predictor==null:return
 var data:Dictionary=game.advisor.snapshot(game)
 var lines:PackedStringArray=[];var forecasts:PackedStringArray=[]
 for i in 4:
  var product:ProductDefinition=ProductCatalog.all()[i]
  lines.append("%s: %d/%d · поднос %d"%[product.display_name,game.checkout.amount_for(product.id),game.checkout.limit_for(product.id),game.tray.amount_for(product.id)])
  forecasts.append("%s ~%d"%[product.display_name,roundi(data.forecast[i])])
 stock.text="Касса / поднос\n"+"\n".join(lines)
 finances.text="Продажи +%d · Расходы −%d\nПрибыль %d" % [game.economy.sales_total,game.economy.expenses_total,game.economy.sales_total-game.economy.expenses_total]
 forecast.text="120 с · "+game.predictor.source+"\n"+"\n".join(forecasts)
 var warning_key:String=str(data.priority.product)+str(data.priority.critical)
 if data.priority.critical and warning_key!=last_warning:get_node("/root/AudioHub").play_sound("warning",3)
 last_warning=warning_key
 warning.text=data.priority.source+"\n"+data.priority.text
 warning.add_theme_color_override("font_color",Color("#B95870") if data.priority.critical else BakeryTheme.INK)
 var gems:int=game.progression.crystals.balance if game.progression!=null else 0
 crystals.text="◆ %d кристаллов"%gems
 repeat_label.text="Поручения: после кампании"
 if game.progression!=null and game.progression.repeatable.enabled:
  repeat_label.text="Поручения: %d/3 готовы · Tab"%game.progression.repeatable.records.filter(func(r):return r.complete).size()
