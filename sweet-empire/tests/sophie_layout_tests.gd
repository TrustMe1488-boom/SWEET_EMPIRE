extends SceneTree
var passed := 0
var failed := 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("SOPHIE_LAYOUT ", "PASS: " if ok else "FAIL: ", title)
func _initialize(): run.call_deferred()
func run():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game)
 await process_frame
 var dialogue := game.campaign_view.dialogue
 var bar := game.dashboard.action_bar
 for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
  root.size = resolution
  dialogue.present(["Привет, Мия! Я Софи. Давай превратим эту маленькую кондитерскую в сладкую империю."], true)
  for i in 3: await process_frame
  var bounds := Rect2(Vector2.ZERO, root.get_visible_rect().size)
  check(dialogue.is_visible_in_tree() and not bar.visible, "Dialogue visible and bar hidden " + str(resolution))
  check(bounds.encloses(dialogue.get_global_rect()), "Dialogue within viewport " + str(resolution))
  check(dialogue.get_global_rect().encloses(dialogue.text_label.get_global_rect()), "Text inside dialogue " + str(resolution))
  check(dialogue.get_global_rect().encloses(dialogue.next_button.get_global_rect()) and dialogue.get_global_rect().encloses(dialogue.close_button.get_global_rect()), "Dialogue buttons inside panel " + str(resolution))
  dialogue.dismiss()
  await process_frame
  check(bar.visible and bounds.encloses(bar.get_global_rect()), "Bar returns inside viewport " + str(resolution))
  game.set_process(false)
  for message in ["Забрать: Печенье", "Передать всё на кассу", "Длинная подсказка о взаимодействии с оборудованием и персонажами, которая должна переноситься и оставаться полностью видимой на экране."]:
   game.hud_view.show_context(1, message)
   for i in 3: await process_frame
   var context := game.hud_view.context
   check(context.visible and bounds.encloses(context.get_global_rect()) and not context.get_global_rect().intersects(bar.get_global_rect()), "Context stays above bar: " + str(resolution) + " " + message.substr(0,20))
   check(context.get_global_rect().encloses(game.hud_view.context_label.get_global_rect()), "Context label stays inside panel " + str(resolution))
  dialogue.present(["Подсказка Софи"], true)
  await process_frame
  check(not bar.visible and not game.hud_view.context.visible, "Dialogue hides conflicting HUD " + str(resolution))
  dialogue.dismiss()
  await process_frame
  check(bar.visible and game.hud_view.context.visible, "Closing dialogue restores HUD " + str(resolution))
  bar.get_child(0).pressed.emit()
  await process_frame
  check(game.modal_kind == &"development" and not game.hud_view.context.visible, "Development menu hides context " + str(resolution))
  game.set_paused(false)
  await process_frame
  check(game.hud_view.context.visible, "Closing menu restores context " + str(resolution))
  game.set_process(true)
 game.queue_free()
 await process_frame
 print("SOPHIE_LAYOUT_RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed == 0 else 1)
