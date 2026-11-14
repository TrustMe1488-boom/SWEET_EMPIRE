extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize():
 run.call_deferred()
func check(condition: bool, description: String):
 if condition: passed += 1
 else: failed += 1
 print("PRESENTATION ", "PASS: " if condition else "FAIL: ", description)
func run():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.hud_view.cards.size() == 5, "Five separate HUD cards")
 check(not game.hud_view.context.visible, "Context stays hidden away from stations")
 check(game.interior.has_node("VisualRoot") and game.interior.has_node("CollisionRoot"), "Interior separates visuals from colliders")
 check(game.interior.oven.has_node("AnimationController") and game.interior.oven.has_node("VisualRoot"), "Reusable animated oven")
 var colliders := game.find_children("*", "CollisionShape3D", true, false)
 check(colliders.size() == 11, "Same eleven physical shapes including Mia; decor adds no blockers")
 var model := game.mia.visual
 check(model.has_node("AnimationController") and game.mia.has_node("CollisionRoot"), "Character separates collision and animation")
 check(not model.tray.visible, "Empty tray hidden")
 game.tray.add(2)
 await physics_frame
 await physics_frame
 check(model.tray.visible and model.cookie_root.get_child_count() == 12, "Two detailed cookies shown on tray")
 check(model.state == &"CarryIdle", "CarryIdle selected")
 Input.action_press("move_right")
 for i in 4: await physics_frame
 Input.action_release("move_right")
 check(model.state == &"CarryWalk", "CarryWalk selected")
 game.mia.play_interaction()
 var coins := game.economy.coins
 var stock := game.tray.count
 model.animate(0.1)
 check(model.interaction_time > 0 and game.economy.coins == coins and game.tray.count == stock, "Interaction animation never moves inventory or money")
 game.tray.take(2)
 await physics_frame
 await physics_frame
 check(model.state == &"Idle" and not model.tray.visible, "Returns to empty Idle")
 Input.action_press("move_right")
 for i in 4: await physics_frame
 Input.action_release("move_right")
 check(model.state == &"Walk", "Walk selected")
 game.mia.position = game.OVEN_ACCESS
 game.production.inventory.add(2)
 await process_frame
 await process_frame
 check(game.hud_view.context.visible and game.hint.text.contains("Забрать"), "Oven context shown")
 Input.action_press("interact")
 for i in 3: await physics_frame
 Input.action_release("interact")
 check(game.tray.count == 2 and game.production.inventory.count == 0, "E input transfers immediately with visual animation")
 game.spawn_customer()
 var visitor := game.queue.first()
 visitor.update_visual(0.1)
 check(visitor.visual.state == &"Walk", "Customer Walk")
 visitor.state = CustomerController.State.Waiting
 visitor.update_visual(0.1)
 check(visitor.visual.state == &"QueueIdle", "Customer QueueIdle")
 visitor.state = CustomerController.State.Leave
 visitor.update_visual(0.1)
 check(visitor.visual.state == &"Leave", "Unserved customer Leave")
 visitor.purchased = true
 visitor.update_visual(0.1)
 visitor.visual.animate(0.1)
 check(visitor.visual.state == &"Happy" and visitor.visual.bag.visible, "Served customer Happy with order bag")
 game.queue.remove(visitor)
 visitor.queue_free()
 await process_frame
 var phase := model.phase
 game.set_paused(true)
 await create_timer(0.08, true).timeout
 check(model.phase == phase, "Pause freezes world animation too")
 game.set_paused(false)
 game.queue_free()
 await process_frame
 print("PRESENTATION_RESULT: %d passed, %d failed" % [passed, failed])
 quit(0 if failed == 0 else 1)
