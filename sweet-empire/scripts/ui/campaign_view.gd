class_name CampaignView
extends Control
var runtime: CampaignRuntime
var game: Node
var information_panel: PanelContainer
var stage_label: Label
var goal_label: Label
var gems_label: Label
var rush_label: Label
var rush_panel: PanelContainer
var toast_label: Label
var toast_time: float = 0
var toast_queue: Array[String] = []
var dialogue: SophieDialogueController
var journal: ColorRect
var journal_column: VBoxContainer
var page: String = "quests"
var victory_screen: Control
var _last_step: int = -1
const TIPS = ["", "Пройди немного с помощью WASD. Камера следует за тобой.", "Печь слева. Подойди к её передней стороне.", "Когда появится E, забери готовое печенье. Повар готовит сам.", "Касса справа. Подойди к ней слева — там место для доставки.", "Нажми E у кассы. Деньги придут позже, когда кассир продаст товар.", "Первый гость терпелив: подожди, пока кассир выдаст ему печенье.", "Отлично! Сделай ещё две непустые доставки. Все три уже идут в кампанию.", "Клавиша 1 открывает развитие. Во время чтения меню игра на паузе.", "Клавиша 2 — персонал. Новому оборудованию потребуется отдельный повар.", "Ты готова! Продолжай доставлять печенье и купи кофемашину. Tab — журнал целей."]
func _ready():
 theme = BakeryTheme.create()
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 var info := PanelContainer.new()
 information_panel = info
 info.position = Vector2(900, 96)
 info.custom_minimum_size = Vector2(334, 0)
 add_child(info)
 var column := VBoxContainer.new()
 info.add_child(column)
 stage_label = BakeryTheme.text("", 16)
 column.add_child(stage_label)
 goal_label = BakeryTheme.text("", 14)
 goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 goal_label.custom_minimum_size.x = 295
 column.add_child(goal_label)
 gems_label = BakeryTheme.text("", 17, Color("#9475aa"))
 column.add_child(gems_label)
 var buttons := HBoxContainer.new()
 column.add_child(buttons)
 for caption in ["Tab · Журнал", "Rush Hour"]:
  var button := Button.new()
  button.text = caption
  button.add_theme_font_size_override("font_size", 15)
  buttons.add_child(button)
  if caption.begins_with("Tab"): button.pressed.connect(func(): show_journal("quests"))
  else: button.pressed.connect(func(): show_journal("rush"))
 rush_panel = PanelContainer.new()
 rush_panel.position = Vector2(900, 260)
 rush_panel.custom_minimum_size = Vector2(334, 0)
 add_child(rush_panel)
 rush_label = BakeryTheme.text("", 18, Color("#80618f"))
 rush_panel.add_child(rush_label)
 rush_panel.hide()
 toast_label = BakeryTheme.text("", 15, Color("#80638e"))
 toast_label.position = Vector2(24, 169)
 toast_label.custom_minimum_size.x = 420
 toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 toast_label.size.x = 440
 add_child(toast_label)
 dialogue = SophieDialogueController.new()
 add_child(dialogue)
 dialogue.greeting_finished.connect(runtime.tutorial.acknowledge)
 dialogue.visibility_requested.connect(func(talking): game.sophie.talking = talking)
 runtime.rewards.granted.connect(_reward)
 runtime.changed.connect(refresh)
 runtime.rush.finished.connect(_rush_finished)
 runtime.campaign.stage_completed.connect(func(stage):
  if stage < 3: show_tip())
 journal = ColorRect.new()
 journal.color = Color(0.19, 0.14, 0.23, 0.75)
 journal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(journal)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 journal.add_child(center)
 var panel := PanelContainer.new()
 panel.custom_minimum_size = Vector2(970, 0)
 center.add_child(panel)
 var outer := VBoxContainer.new()
 outer.add_theme_constant_override("separation", 12)
 panel.add_child(outer)
 var tabs := HBoxContainer.new()
 outer.add_child(tabs)
 for title in ["Задания", "Достижения", "Rush Hour", "Совет Софи", "Аналитика", "Поручения"]:
  var button := Button.new()
  button.text = title
  tabs.add_child(button)
  match title:
   "Задания": button.pressed.connect(func(): build_page("quests"))
   "Достижения": button.pressed.connect(func(): build_page("achievements"))
   "Rush Hour": button.pressed.connect(func(): build_page("rush"))
   "Поручения": button.pressed.connect(func():build_page("repeatable"))
   "Аналитика": button.pressed.connect(func(): build_page("analytics"))
   "Совет Софи": button.pressed.connect(func():
    game.set_paused(false)
    show_tip())
 var scroll := ScrollContainer.new()
 scroll.custom_minimum_size = Vector2(920, 420)
 outer.add_child(scroll)
 journal_column = VBoxContainer.new()
 journal_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 journal_column.add_theme_constant_override("separation", 10)
 scroll.add_child(journal_column)
 var close := Button.new()
 close.text = "Вернуться в кондитерскую · Esc"
 close.pressed.connect(func(): game.set_paused(false))
 outer.add_child(close)
 journal.hide()
 refresh()
func show_tip():
 var step := runtime.tutorial.step
 if step == 0: dialogue.present(["Привет, Мия! Я Софи. Давай превратим эту маленькую кондитерскую в сладкую империю.", "Повар печёт автоматически. Твоя первая задача — доставить печенье к кассе. Начнём с движения!"], false)
 elif runtime.tutorial.done:
  var message := "Ты создала свою империю! Можно спокойно развивать кондитерскую и завершать задания."
  if not runtime.campaign.won:
   message = "Финиш близко! " if runtime.campaign.stage == 3 else "Мы растём! "
   if runtime.campaign.can_start_rush(runtime.stats):
    message += "Подготовь запас каждого товара на кассе. Rush Hour запускается только после твоего подтверждения."
   else:
    for goal in runtime.campaign.objectives(runtime.stats, runtime.tutorial):
     if not goal.complete:
      message += "Следующая цель: %s (%s/%s). Tab покажет все цели и награды." % [goal.title, _number(goal.progress), _number(goal.target)]
      break
  dialogue.present([message], true)
 else: dialogue.present([TIPS[step]], true)
func refresh():
 if stage_label == null: return
 stage_label.text = "Бесконечный режим" if runtime.campaign.endless else "Глава %d · %s" % [runtime.campaign.stage, CampaignDefinitions.TITLES[runtime.campaign.stage - 1]]
 goal_label.text = "Кампания завершена. Кондитерская растёт дальше."
 if not runtime.tutorial.done: goal_label.text = "Софи · %d/10: %s" % [runtime.tutorial.step, TutorialManager.STEPS[runtime.tutorial.step]]
 elif not runtime.campaign.won:
  for goal in runtime.campaign.objectives(runtime.stats, runtime.tutorial):
   if not goal.complete:
    goal_label.text = "%s · %s/%s" % [goal.title, _number(goal.progress), _number(goal.target)]
    break
 gems_label.text = "Кристаллы: %d" % runtime.crystals.balance
 if _last_step != runtime.tutorial.step:
  _last_step = runtime.tutorial.step
  show_tip()
 if journal != null and journal.visible: build_page(page)
func _number(value: float) -> String:
 return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.2f" % value
func show_journal(value: String):
 game.set_paused(false)
 game.modal_kind = &"journal"
 game.get_tree().paused = true
 build_page(value)
 journal.show()
func build_page(value: String):
 page = value
 for child in journal_column.get_children():
  journal_column.remove_child(child)
  child.queue_free()
 if value == "repeatable":
  if runtime.campaign.endless:runtime.repeatable.activate()
  journal_column.add_child(BakeryTheme.text("Повторяемые поручения Софи",26))
  if not runtime.repeatable.enabled:journal_column.add_child(BakeryTheme.text("Доступны после победы и перехода в бесконечный режим.",18))
  for row in runtime.repeatable.records:
   var button:=Button.new();button.text="%s · %d/%d · ◆ %d"%[row.title,row.progress,row.target,row.reward]
   button.custom_minimum_size.y=60;button.disabled=not row.complete
   button.pressed.connect(func():runtime.repeatable.claim(row.id);build_page("repeatable"));journal_column.add_child(button)
 elif value == "analytics":
  journal_column.add_child(BakeryTheme.text("Софи · спрос на следующие 120 секунд", 26))
  journal_column.add_child(BakeryTheme.text("Источник: %s · обновлено на %.1f с игрового времени" % [game.predictor.source, game.predictor.last_update], 17))
  for i in 4:
   var product: ProductDefinition = ProductCatalog.all()[i]
   journal_column.add_child(BakeryTheme.text("%s: ~%d заказов" % [product.display_name, roundi(game.predictor.forecast[i])], 21))
   var bar := ProgressBar.new()
   bar.max_value = maxf(20, game.predictor.forecast.max())
   bar.value = game.predictor.forecast[i]
   bar.show_percentage = false
   bar.custom_minimum_size = Vector2(820, 15)
   journal_column.add_child(bar)
  var traffic:Dictionary=game.pedestrians.counts
  journal_column.add_child(BakeryTheme.text("Потенциальный спрос: %s\nУпущенный спрос: %s\nВходы: %s\nПодтверждённые заказы: %d\nПродажи и уходы: %d / %d"%[str(traffic.potential),str(traffic.missed),str(traffic.entries),game.demand.records.filter(func(r):return r.event=="OrderCreated").size(),int(runtime.stats.amount("served")),int(runtime.stats.amount("left"))],16))
  journal_column.add_child(BakeryTheme.text("Предупреждения по правилам · отдельно от ML", 18))
  journal_column.add_child(BakeryTheme.text(game.advisor.advise(game), 18))
  var export_button := Button.new()
  export_button.text = "Экспорт событий CSV в user://demand-events.csv"
  export_button.pressed.connect(func(): export_button.text = "CSV: " + str(game.demand.export_csv("user://demand-events.csv")))
  journal_column.add_child(export_button)
 elif value == "quests":
  journal_column.add_child(BakeryTheme.text("Текущая глава: " + CampaignDefinitions.TITLES[runtime.campaign.stage - 1], 25))
  for goal in runtime.campaign.objectives(runtime.stats, runtime.tutorial):
   journal_column.add_child(BakeryTheme.text(("✓ " if goal.complete else "○ ") + "%s  %s / %s" % [goal.title, _number(goal.progress), _number(goal.target)], 18))
  journal_column.add_child(BakeryTheme.text("Задания Софи · количество — с начала кампании; серия — с открытия главы 3", 15, Color("#92768f")))
  for quest in CampaignDefinitions.QUESTS:
   var record: Dictionary = runtime.quests.records[quest.id]
   var status := "Выполнено" if record.complete else ("%d/%d" % [record.progress, quest.target] if record.active else "Откроется в главе %d" % quest.stage)
   var reward := "%d монет" % quest.coins if quest.coins > 0 else "%d кристаллов" % quest.gems
   journal_column.add_child(BakeryTheme.text("%s · %s\n%s · %s" % [quest.title, status, quest.description, reward], 17))
 elif value == "achievements":
  journal_column.add_child(BakeryTheme.text("Достижения", 28))
  for achievement in CampaignDefinitions.ACHIEVEMENTS:
   journal_column.add_child(BakeryTheme.text("%s %s · %d кристаллов" % ["✓" if runtime.achievements.unlocked.has(achievement.id) else "○", achievement.title, achievement.gems], 20))
 else:
  journal_column.add_child(BakeryTheme.text("Rush Hour · финальное испытание", 28))
  var explanation := "90 секунд, 15 обслуженных гостей. Поток каждые 3–4 с, терпение каждого типа +20%.\nПроизводство обычное. Доставка — вручную. Подготовьте запас на кассе.\nПри неудаче вся попытка откатится к контрольной точке, включая награды.\nВо время попытки покупки, найм и улучшения недоступны."
  if runtime.rush.last_result == "failed": explanation = "Попытка не удалась. Контрольная точка полностью восстановлена.\n\n" + explanation
  var description := BakeryTheme.text(explanation, 18)
  description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
  description.custom_minimum_size.x = 870
  journal_column.add_child(description)
  var button := Button.new()
  button.custom_minimum_size.y = 54
  button.text = "Подтвердить запуск" if value == "rush_confirm" else "Я подготовил запас — начать"
  button.disabled = runtime.rush.active or runtime.rush.won or not runtime.campaign.can_start_rush(runtime.stats)
  if button.disabled:
   journal_column.add_child(BakeryTheme.text("Нужны: глава 3, станция тортов с поваром, 100 гостей и рейтинг 4,5.", 17))
  button.pressed.connect(func():
   if value != "rush_confirm": build_page("rush_confirm")
   else:
    game.set_paused(false)
    if not runtime.rush.start(true): toast_queue.append("Испытание сейчас недоступно."))
  journal_column.add_child(button)
func _reward(_id: String, title: String, coins: int, gems: int):
 toast_queue.append(title + "\n" + ("+%d монет" % coins if coins > 0 else "+%d кристаллов" % gems))
func _rush_finished(success: bool):
 if not success:
  toast_queue.clear()
  toast_label.text = ""
  show_journal("rush")
func show_victory():
 if victory_screen != null or not runtime.campaign.won: return
 game.set_paused(true)
 game.pause_panel.hide()
 game.modal_kind = &"victory"
 victory_screen = preload("res://scenes/victory.tscn").instantiate()
 add_child(victory_screen)
 victory_screen.main_menu_requested.connect(func(): game.get_node("/root/GameSession").return_to_menu(game))
 var coins: int = 0
 for entry in game.economy.history:
  if entry.category == &"reward" and runtime.rewards.claimed.has(str(entry.subject)): coins += int(entry.amount)
 victory_screen.set_results(runtime.stats, runtime.crystals.total_earned(), coins, runtime.rewards.claimed.size())
 victory_screen.continue_requested.connect(func():
  if runtime.campaign.enter_endless():
   victory_screen.queue_free()
   victory_screen = null
   game.set_paused(false)
   runtime.repeatable.activate()
   refresh())
func _process(delta: float):
 if dialogue != null:
  dialogue.visible = dialogue.requested_visible and game.modal_kind == &""
  game.sophie.talking = dialogue.visible
 var world_mode: bool = game.modal_kind == &""
 information_panel.visible = world_mode
 toast_label.visible = world_mode
 rush_panel.visible = runtime.rush.active and world_mode
 rush_label.text = "Rush Hour · %d с\nОбслужено: %d / 15" % [ceili(runtime.rush.remaining), runtime.rush.served] if runtime.rush.active else ""
 if not world_mode: return
 toast_time -= delta
 if toast_time <= 0:
  toast_label.text = ""
  if not toast_queue.is_empty():
   toast_label.text = toast_queue.pop_front()
   toast_time = 3.6
func hide_modals():
 if journal != null: journal.hide()
