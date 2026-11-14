extends SceneTree
var failures: int = 0
func _initialize(): run.call_deferred()
func check(value: bool, title: String):
 if not value: failures += 1
 print("STAGE4_GPU ","PASS: " if value else "FAIL: ",title)
func settle(frames: int=15):
 for i in frames: await process_frame
 await RenderingServer.frame_post_draw
func shot(name: String):
 check(root.get_texture().get_image().save_png("res://Documentation/"+name+".png")==OK,"Screenshot "+name)
func run():
 if DisplayServer.get_name()=="headless": quit(1);return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 var menu: Control=load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu)
 await settle()
 check(menu.is_inside_tree(),"Main menu loads under real renderer")
 menu.queue_free()
 await process_frame
 var game: BakeryGame=load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled=true
 root.add_child(game)
 await settle()
 game.spawn_customer()
 var protected:=game.queue.first()
 protected.position=game.queue.slot(protected)
 protected.state=CustomerController.State.Waiting
 game.checkout.add(1,&"COOKIE")
 game.cashier.advance(2)
 game.progression.tutorial.step=10
 game.progression.tutorial.first_served=true
 game.progression.tutorial.first_customer_spawned=true
 game.campaign_view.dialogue.dismiss()
 game.economy.grant_reward("render_fixture",10000)
 game.development.buy(&"COFFEE");game.personnel.hire(&"COFFEE")
 game.development.buy(&"CUPCAKE");game.personnel.hire(&"CUPCAKE")
 game.zones.unlock_zone3_for_campaign(true)
 game.development.buy(&"CAKE");game.personnel.hire(&"CAKE")
 game._next_customer_id=4
 game.spawner.rng.seed=20261114
 for i in 5: game.spawn_customer()
 for c in game.queue.customers: c.patience_protected=true
 check(game.queue.customers.size()==5,"Five visible customers prepared for benchmark")
 game.spawner.set_process(false)
 game.campaign_view.dialogue.dismiss()
 await settle(180)
 game.predictor.refresh()
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  shot("stage4-game-%dx%d"%[resolution.x,resolution.y])
  game.campaign_view.show_journal("analytics")
  await settle()
  shot("stage4-analytics-%dx%d"%[resolution.x,resolution.y])
  check(game.campaign_view.journal_column.get_child_count()>=12,"Analytics rows, real forecast bars, CSV control")
  game.set_paused(false)
 DisplayServer.window_set_size(Vector2i(1920,1080))
 await settle()
 # Keep five visible waiting guests for a reproducible measured scene.
 for c in game.queue.customers: c.patience_protected=true
 var features:=game.demand.features()
 var start:=Time.get_ticks_usec()
 for i in 10000: game.predictor.predict(features)
 var prediction_us: float=(Time.get_ticks_usec()-start)/10000.0
 var times: Array[float]=[]
 var previous:=Time.get_ticks_usec()
 for i in 180:
  await process_frame
  var now:=Time.get_ticks_usec()
  times.append((now-previous)/1000.0)
  previous=now
 times.sort()
 var mean: float=0
 for time in times:mean+=time/times.size()
 var report:={"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","frames":times.size(),"mean_ms":mean,"mean_FPS":1000.0/mean,"median_ms":times[90],"p95_ms":times[171],"predictor_us":prediction_us,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"customers":game.queue.customers.size(),"zones":game.zones.highest_open(),"vsync":false}
 var file:=FileAccess.open("res://Documentation/stage4-performance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(report,"  "));file.close()
 print("STAGE4_PERFORMANCE ",JSON.stringify(report))
 check(game.predictor.source=="ML" and prediction_us<1000,"Runtime ML runs in GDScript below one millisecond")
 game.queue_free()
 await process_frame
 print("STAGE4_GPU_RESULT failures=",failures)
 quit(1 if failures else 0)
