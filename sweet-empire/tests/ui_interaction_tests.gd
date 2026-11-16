extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize(): run.call_deferred()
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("UI ","PASS: " if ok else "FAIL: ",title)
func run():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game); await process_frame
 var settings: ControlSettings
 for child in game.get_node("HUD").get_children():
  if child is ControlSettings: settings = child
 var panel := Control.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.add_child(panel)
 var button := Button.new(); button.position = Vector2(350,300); button.size = Vector2(100,50)
 panel.add_child(button)
 var clicks := {"count":0}
 button.pressed.connect(func():clicks.count += 1)
 for resolution in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
  root.size = resolution
  await process_frame; await process_frame
  var before: int = clicks.count
  settings.click_cursor(button.get_global_rect().get_center() / root.get_visible_rect().size)
  await process_frame
  check(clicks.count == before + 1,"Exactly one virtual click at " + str(resolution))
 check(not game.gesture_bridge.active,"Virtual UI test never enables camera")
 panel.queue_free(); game.queue_free(); await process_frame
 print("UI_INTERACTION_RESULT: %d passed, %d failed" % [passed,failed])
 quit(0 if failed==0 else 1)
