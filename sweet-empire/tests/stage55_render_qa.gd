extends SceneTree
var failures:int=0
var checks:int=0
func _initialize():run.call_deferred()
func check(ok:bool,title:String):
 checks+=1
 if not ok:failures+=1
 print("STAGE55_GPU ","PASS " if ok else "FAIL ",title)
func settle(frames:int=15):
 for i in frames:await process_frame
 await RenderingServer.frame_post_draw
func shot(name:String):check(root.get_texture().get_image().save_png("res://Documentation/"+name+".png")==OK,"Screenshot "+name)
func run():
 if DisplayServer.get_name()=="headless":quit(1);return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 var session:GameSessionManager=root.get_node("GameSession")
 var menu:Control=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
 menu.shop_button.pressed.emit();await process_frame;await process_frame
 var shop:CosmeticShopController=current_scene
 session.wallet.grant_once("render-fixture",250)
 var sizes:Array=[Vector2i(1280,720),Vector2i(1920,1080),Vector2i(960,540)]
 var ids:Array=[&"MIA_MAID",&"MIA_ROYAL",&"MIA_WINTER"]
 for index in 3:
  DisplayServer.window_set_size(sizes[index]);shop.select_category("MIA_OUTFIT");shop.select_item(ids[index]);await settle()
  shot("stage55-"+str(ids[index]).to_lower())
  shop.perform_action();shop.perform_action()
 shop.back();await process_frame;await process_frame;session.start_or_continue();await process_frame;await process_frame
 var game:BakeryGame=current_scene
 game.progression.tutorial.step=10
 game.spawn_customer();var first:CustomerController=game.queue.first();first.position=game.queue.slot(first);first.state=CustomerController.State.Waiting
 game.checkout.add(1);game.cashier.advance(2)
 game.economy.grant_reward("render-only",20000)
 game.development.buy(&"COFFEE");game.personnel.hire(&"COFFEE");game.development.buy(&"CUPCAKE");game.personnel.hire(&"CUPCAKE")
 game.zones.unlock_zone3_for_campaign(true);game.development.buy(&"CAKE");game.personnel.hire(&"CAKE")
 game.progression.tray_upgrades.upgrade(1);game.progression.tray_upgrades.upgrade(2);game.checkout_upgrades.upgrade(1);game.checkout_upgrades.upgrade(2)
 game.campaign_view.dialogue.dismiss()
 for i in 5:game.spawn_customer()
 for customer in game.queue.customers:customer.patience_protected=true
 for i in 8:game.pedestrians.request_pedestrian()
 for i in game.pedestrians.visitors.size():game.pedestrians.visitors[i].position=Vector3(8.4,0,-7+i*2)
 for product in ProductCatalog.all():game.tray.add(3,product.id)
 game.update_hud();await settle(90)
 var settings:ControlSettings
 for child in game.get_node("HUD").get_children():
  if child is ControlSettings:settings=child
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,540)]:
  DisplayServer.window_set_size(resolution);await settle()
  shot("stage55-town-%dx%d"%[resolution.x,resolution.y])
  game.open_analytics();await settle();shot("stage55-analytics-%dx%d"%[resolution.x,resolution.y]);game.set_paused(false)
  settings.open();await settle();shot("stage55-settings-%dx%d"%[resolution.x,resolution.y]);game.set_paused(false)
  game.set_paused(true);await settle(3)
  var resume:Button=game.hud_view.pause_buttons[0]
  var screen:Vector2=resume.get_global_transform_with_canvas()*(resume.size/2)
  settings.click_cursor(screen/root.get_visible_rect().size)
  await process_frame;await process_frame
  check(not paused,"Virtual cursor clicks paused menu at "+str(resolution))
  game.set_paused(false)
 DisplayServer.window_set_size(Vector2i(1920,1080));await settle()
 # Actual webcam inference runs in a separate process; lack of a visible hand is recorded.
 game.gesture_bridge.start("python")
 var camera_wait:float=0
 while camera_wait<8 and not game.gesture_bridge.camera_ready:
  await create_timer(0.1).timeout;camera_wait+=0.1
 check(game.gesture_bridge.active and game.gesture_bridge.camera_ready and game.gesture_bridge.last_sequence>0,"Real camera worker exchanges local normalized packets")
 game.progression.stats.data.deliveries=5;game.progression.stats.data.sales_income=200;game.progression.stats.data.served=100
 game.rating.value=4.8;game.rating.changed.emit();game.progression.refresh()
 check(game.progression.rush.start(true),"Confirmed timed Rush starts in expanded scene")
 var frames:Array[float]=[];var last:int=Time.get_ticks_usec()
 for i in 180:
  for station in game.development.stations.values():
   if station.inventory.count>0:station.inventory.take(station.inventory.count)
  while game.pedestrians.visitors.size()<8:game.pedestrians.request_pedestrian()
  await process_frame
  var now:int=Time.get_ticks_usec();frames.append((now-last)/1000.0);last=now
 frames.sort();var mean:float=0
 for value in frames:mean+=value/frames.size()
 var report:Dictionary={"renderer":RenderingServer.get_video_adapter_name(),"resolution":"1920x1080","frames":180,"mean_ms":mean,"mean_FPS":1000/mean,"p95_ms":frames[171],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"pedestrians":game.pedestrians.visitors.size(),"queue":game.queue.customers.size(),"zones":game.zones.highest_open(),"camera_packets":game.gesture_bridge.last_sequence,"rush_mode":game.spawner.rush_mode,"rush_remaining":game.progression.rush.remaining,"paused":paused,"audio_music":root.get_node("AudioHub").current}
 var file:=FileAccess.open("res://Documentation/stage55-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();print("STAGE55_PERFORMANCE ",JSON.stringify(report))
 game.gesture_bridge.stop();await create_timer(1).timeout
 check(game.gesture_bridge.pid==-1,"Camera process shut down")
 print("STAGE55_GPU_RESULT: checks=%d failed=%d"%[checks,failures])
 if failures:quit(1)
 else:root.get_node("AudioHub").quit_game()
