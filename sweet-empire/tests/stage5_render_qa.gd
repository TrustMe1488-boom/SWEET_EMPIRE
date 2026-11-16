extends SceneTree
var failed:int=0
var checks:int=0
var measurements:Array=[]
func _initialize():run.call_deferred()
func check(value:bool,title:String):
 checks+=1
 if not value:failed+=1
 print("STAGE5_GPU ","PASS: " if value else "FAIL: ",title)
func settle(frames:int=15):
 for i in frames:await process_frame
 await RenderingServer.frame_post_draw
func shot(name:String):
 check(root.get_texture().get_image().save_png("res://Documentation/"+name+".png")==OK,"Screenshot "+name)
func benchmark(name:String):
 await settle(30)
 var times:Array[float]=[]
 var previous:=Time.get_ticks_usec()
 for i in 120:
  await process_frame
  var now:=Time.get_ticks_usec()
  times.append((now-previous)/1000.0);previous=now
 times.sort()
 var mean:float=0
 for time in times:mean+=time/times.size()
 var result:={"case":name,"frames":120,"mean_ms":mean,"mean_fps":1000.0/mean,"median_ms":times[60],"p95_ms":times[114],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
 measurements.append(result)
 print("STAGE5_PERFORMANCE ",JSON.stringify(result))
func run():
 if DisplayServer.get_name()=="headless":quit(1);return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 var session:GameSessionManager=root.get_node("GameSession")
 var menu:Control=load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu);current_scene=menu
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  shot("stage5-menu-%dx%d"%[resolution.x,resolution.y])
 DisplayServer.window_set_size(Vector2i(1920,1080))
 await benchmark("main_menu_1080p")
 menu.shop_button.pressed.emit()
 await process_frame;await process_frame
 var shop:CosmeticShopController=current_scene
 check(shop!=null and root.find_children("*","BakeryGame",true,false).is_empty(),"Real main-menu shop opens with no gameplay")
 # Funding is restricted to this QA runner, never normal startup.
 session.wallet.grant_once("gpu_fixture",300)
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,540)]:
  DisplayServer.window_set_size(resolution)
  for category in CosmeticCatalog.CATEGORIES:
   shop.select_category(category)
   for item in CosmeticCatalog.in_category(category):
    shop.select_item(item.id)
    await settle(8)
    shot("stage5-%s-%dx%d"%[str(item.id).to_lower(),resolution.x,resolution.y])
   check(shop.action.get_global_rect().end.x<=shop.size.x+1 and shop.action.get_global_rect().end.y<=shop.size.y+1,"Action stays in virtual canvas "+category)
 DisplayServer.window_set_size(Vector2i(1920,1080))
 for pair in [["MIA_OUTFIT",&"MIA_LAVENDER"],["INTERIOR_THEME",&"INTERIOR_GOLD"],["DESSERT_STYLE",&"DESSERT_FESTIVE"]]:
  shop.select_category(pair[0]);shop.select_item(pair[1])
  await benchmark("shop_"+pair[0].to_lower()+"_1080p")
  shop.action.pressed.emit();shop.action.pressed.emit()
 check(session.wallet.balance==160,"Real shop UI buys and equips three cosmetics at agreed prices")
 shop.back()
 await process_frame;await process_frame
 session.start_or_continue()
 await process_frame;await process_frame
 var game:BakeryGame=current_scene
 game.progression.tutorial.step=10
 game.spawn_customer()
 var first:=game.queue.first()
 first.position=game.queue.slot(first);first.state=CustomerController.State.Waiting
 game.checkout.add(1,&"COOKIE");game.cashier.advance(2)
 game.progression.tutorial.first_served=true
 game.economy.grant_reward("gpu_setup",10000)
 game.development.buy(&"COFFEE");game.personnel.hire(&"COFFEE")
 game.development.buy(&"CUPCAKE");game.personnel.hire(&"CUPCAKE")
 game.zones.unlock_zone3_for_campaign(true)
 game.development.buy(&"CAKE");game.personnel.hire(&"CAKE")
 game.progression.tray_upgrades.upgrade(1);game.progression.tray_upgrades.upgrade(2)
 for product in ProductCatalog.all():
  game.development.get_station(product.id).advance(product.base_time*5)
  game.tray.add(3,product.id)
 game.update_hud()
 for i in 5:game.spawn_customer()
 game.spawner.set_process(false)
 for c in game.queue.customers:c.patience_protected=true
 game.campaign_view.dialogue.dismiss()
 await settle(180)
 check(game.queue.customers.size()==5 and game.zones.highest_open()==3,"Expanded styled bakery has five customers and all zones")
 for resolution in [Vector2i(1920,1080),Vector2i(1280,720),Vector2i(960,540)]:
  DisplayServer.window_set_size(resolution)
  await settle()
  shot("stage5-bakery-%dx%d"%[resolution.x,resolution.y])
 DisplayServer.window_set_size(Vector2i(1920,1080))
 await benchmark("bakery_gold_festive_lavender_1080p")
 game.set_paused(true);game.hud_view.pause_buttons[1].pressed.emit()
 await process_frame;await process_frame
 menu=current_scene
 var before:float=game.demand.game_time
 menu.shop_button.pressed.emit()
 await process_frame;await process_frame
 shop=current_scene
 await settle()
 check(not game.is_inside_tree() and game.demand.game_time==before,"Live bakery remains fully suspended while shop renders")
 await benchmark("shop_with_retained_bakery_1080p")
 var file:=FileAccess.open("res://Documentation/stage5-performance.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),"renderer":"Compatibility","resolution":"1920x1080","vsync":false,"measurements":measurements},"  "));file.close()
 print("STAGE5_GPU_RESULT: checks=%d failed=%d"%[checks,failed])
 quit(1 if failed else 0)
