extends SceneTree
var passed:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(value:bool,title:String):
 if value:passed+=1
 else:failed+=1
 print("STAGE5 ","PASS: " if value else "FAIL: ",title)
func roundtrip(data:Dictionary)->Dictionary:return JSON.parse_string(JSON.stringify(data))
func mesh_colors(node:Node)->Array:
 var colors:Array=[]
 if node is GeometryInstance3D and node.material_override is StandardMaterial3D:colors.append(node.material_override.albedo_color)
 for child in node.get_children():colors.append_array(mesh_colors(child))
 return colors
func unit_tests():
 check(CosmeticCatalog.validate().is_empty(),"Catalog IDs, resources, categories and defaults valid")
 check(CosmeticCatalog.all().size()==12,"Twelve authored cosmetics including the original nine")
 var prices:={"MIA_MAID":30,"MIA_ROYAL":50,"MIA_WINTER":40,"MIA_CLASSIC":0,"MIA_MINT":20,"MIA_LAVENDER":40,"INTERIOR_PINK":0,"INTERIOR_MINT":30,"INTERIOR_GOLD":60,"DESSERT_CLASSIC":0,"DESSERT_CARAMEL":20,"DESSERT_FESTIVE":40}
 for item in CosmeticCatalog.all():check(item.price==prices[str(item.id)] and item.is_free==(item.price==0),"Agreed crystal price "+str(item.id))
 var wallet:=CrystalWallet.new()
 var manager:=CosmeticManager.new(wallet)
 check(wallet.balance==0 and manager.owns(&"MIA_CLASSIC") and manager.owns(&"INTERIOR_PINK") and manager.owns(&"DESSERT_CLASSIC"),"Empty wallet and three free defaults")
 check(manager.status(&"MIA_CLASSIC")==CosmeticManager.Status.EQUIPPED and manager.status(&"MIA_MINT")==CosmeticManager.Status.LOCKED,"Initial item states")
 var before:=manager.get_save_data()
 check(not manager.purchase(&"MIA_MINT") and wallet.balance==0 and manager.get_save_data()==before,"Insufficient crystals leave all state unchanged")
 check(not manager.equip(&"MIA_LAVENDER") and not manager.purchase(&"UNKNOWN"),"Unknown purchase and unowned equip rejected")
 check(not wallet.try_spend_once("bad",-1) and not wallet.try_spend_once("zero",0),"Wallet rejects negative and zero debit")
 wallet.grant_once("test-earned",200)
 var observation:={"owned":false,"reentry":true}
 var listener:=func():
  observation.owned=manager.owns(&"MIA_MINT")
  observation.reentry=manager.purchase(&"MIA_MINT")
 wallet.changed.connect(listener)
 check(manager.purchase(&"MIA_MINT") and wallet.balance==180,"Exact single debit and ownership")
 check(observation.owned and not observation.reentry,"Observers see atomic state and cannot reenter purchase")
 wallet.changed.disconnect(listener)
 check(not manager.purchase(&"MIA_MINT") and wallet.balance==180,"Duplicate purchase never spends twice")
 check(manager.equip(&"MIA_MINT") and manager.status(&"MIA_MINT")==CosmeticManager.Status.EQUIPPED,"Purchased outfit equipped")
 check(manager.equip(&"MIA_CLASSIC") and manager.equip(&"MIA_MINT") and wallet.balance==180,"Switching and re-equipping are free")
 check(not wallet.try_spend_once("cosmetic:MIA_MINT",20) and wallet.balance==180,"Debit ledger deduplicates key independently")
 var clone:=CrystalWallet.new()
 check(clone.load_save_data(roundtrip(wallet.get_save_data())) and clone.balance==180,"Wallet serializes earned and spent ledgers")
 check(wallet.total_earned()==200 and wallet.total_spent()==20,"Lifetime earned rewards are separate from current balance")
 check(clone.load_save_data({"version":1,"balance":5,"claims":{"legacy":5}}),"Legacy wallet v1 supported")
 var corrupted:=wallet.get_save_data();corrupted.balance=999
 check(not clone.load_save_data(corrupted) and clone.balance==5,"Corrupt wallet rejected atomically")
 var cm:=CosmeticManager.new(wallet)
 check(cm.load_save_data(roundtrip(manager.get_save_data())) and cm.active("MIA_OUTFIT").id==&"MIA_MINT","Cosmetics JSON roundtrip")
 var invalid:=manager.get_save_data();invalid.owned.append("UNKNOWN")
 var saved:=cm.get_save_data()
 check(not cm.load_save_data(invalid) and cm.get_save_data()==saved,"Unknown owned ID rejects whole load")
 invalid=manager.get_save_data();invalid.active.MIA_OUTFIT="INTERIOR_PINK"
 check(not cm.load_save_data(invalid) and cm.get_save_data()==saved,"Cross-category active ID rejects whole load")
 manager.purchase_commit=func(_id,_cost):return false
 var prior:=wallet.get_save_data()
 check(not manager.purchase(&"INTERIOR_MINT") and wallet.get_save_data()==prior and not manager.owns(&"INTERIOR_MINT"),"Failed transaction commit restores currency and ownership")
 manager.purchase_commit=Callable()
 check(manager.purchase(&"INTERIOR_MINT") and manager.purchase(&"DESSERT_CARAMEL"),"Independent categories purchasable")
 check(manager.equip(&"INTERIOR_MINT") and manager.equip(&"DESSERT_CARAMEL") and manager.active("MIA_OUTFIT").id==&"MIA_MINT","One active item per category")
func deliver(game:BakeryGame):
 game.production.advance(20)
 game.mia.position=game.OVEN_ACCESS;game._process(0);game.interact()
 game.mia.position=game.CHECKOUT_ACCESS;game._process(0);game.interact()
func serve(game:BakeryGame):
 if game.queue.first()==null:game.spawn_customer()
 var customer:CustomerController=game.queue.first()
 customer.position=game.queue.slot(customer);customer.state=CustomerController.State.Waiting
 game.cashier.advance(2)
func run():
 unit_tests()
 var session:GameSessionManager=root.get_node("GameSession")
 var menu:Control=load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu);current_scene=menu
 await process_frame
 var initial_profile:=session.get_save_data()
 check(session.load_save_data(roundtrip(initial_profile)),"Shared profile supports validated in-memory JSON roundtrip")
 var corrupt_profile:=roundtrip(initial_profile)
 corrupt_profile.wallet={"version":2,"balance":30,"claims":{"not_committed":30},"spends":{}}
 corrupt_profile.cosmetics.owned.append("UNKNOWN")
 check(not session.load_save_data(corrupt_profile) and session.wallet.balance==0,"Invalid cosmetic profile cannot partially replace wallet")
 var unpaid:=roundtrip(initial_profile)
 unpaid.cosmetics.owned.append("MIA_MINT");unpaid.cosmetics.active.MIA_OUTFIT="MIA_MINT"
 check(not session.load_save_data(unpaid) and session.wallet.balance==0,"Session rejects paid ownership without its debit ledger")
 var orphan:=roundtrip(initial_profile)
 orphan.wallet={"version":2,"balance":0,"claims":{"fixture":20},"spends":{"cosmetic:MIA_MINT":20}}
 check(not session.load_save_data(orphan) and session.wallet.balance==0,"Session rejects debit without the purchased item")
 check(menu.shop_button!=null and not session.has_game(),"MainMenu offers shop before any bakery")
 menu.shop_button.pressed.emit()
 await process_frame;await process_frame
 var shop:CosmeticShopController=current_scene
 check(shop!=null and shop.viewport.own_world_3d and shop.preview.model is ChibiVisual,"MainMenu opens real 3D shop scene")
 check(root.find_children("*","BakeryGame",true,false).is_empty() and not session.has_game(),"Shop creates no BakeryGame or production session")
 check(shop.balance_label.text.contains("0") and shop.manager.wallet==session.wallet,"Shop uses existing shared CrystalWallet")
 var free_profile:=session.cosmetics.get_save_data()
 var wallet_before:=session.wallet.get_save_data()
 shop.select_item(&"MIA_LAVENDER")
 check(shop.action.disabled and shop.preview.selected.id==&"MIA_LAVENDER","Locked outfit has real preview but disabled unaffordable purchase")
 check(session.wallet.get_save_data()==wallet_before and session.cosmetics.get_save_data()==free_profile,"Preview never purchases, equips or spends")
 var classic_colors:=mesh_colors(shop.preview.model)
 shop.select_item(&"MIA_MINT")
 check(classic_colors!=mesh_colors(shop.preview.model),"Outfit preview changes actual materials")
 shop.select_category("INTERIOR_THEME");shop.select_item(&"INTERIOR_GOLD")
 check(shop.preview.model is BakeryInterior and shop.preview.model.find_children("*","CollisionShape3D",true,false).is_empty(),"Interior diorama reuses real visuals without physics")
 shop.select_category("DESSERT_STYLE");shop.select_item(&"DESSERT_FESTIVE")
 check(shop.preview.model.get_child_count()==4 and session.cosmetics.get_save_data()==free_profile,"All four styled desserts preview without changing active style")
 shop.back_button.pressed.emit()
 await process_frame;await process_frame
 menu=current_scene
 check(menu!=null and not session.has_game() and session.wallet.balance==0,"Shop returns to MainMenu without starting or funding game")
 var start:Button=menu.find_children("*","Button",true,false)[0]
 start.pressed.emit()
 await process_frame;await process_frame
 var game:BakeryGame=current_scene
 check(game.find_children("ShopButton","BaseButton",true,false).is_empty() and not InputMap.has_action("cosmetic_shop"),"Bakery HUD and gameplay keys provide no shop entry")
 check(game!=null and session.active_game==game and game.progression.crystals==session.wallet,"MainMenu campaign binds same session wallet")
 game.process_mode=Node.PROCESS_MODE_DISABLED
 game.campaign_view.dialogue.advance();game.campaign_view.dialogue.advance()
 game.events.publish(&"MiaMoved",{"distance":1.1})
 for i in 3:
  deliver(game)
  if i==0:serve(game)
 game.toggle_management(&"development");game.toggle_management(&"personnel");game.handle_escape()
 for i in 19:deliver(game);serve(game)
 check(game.progression.tutorial.done and game.progression.stats.amount("served")==20,"Authored tutorial and twenty real cookie sales completed")
 check(game.development.buy(&"COFFEE") and session.wallet.balance==25,"Campaign earns twenty-five crystals without test funding")
 var stats:=game.progression.get_save_data()
 var economy:=game.economy.get_save_data()
 var rng_state:int=game.spawner.rng.state
 var elapsed:float=game.production.elapsed
 var clock:float=game.demand.game_time
 game.set_paused(true)
 game.hud_view.pause_buttons[1].pressed.emit()
 await process_frame;await process_frame
 menu=current_scene
 check(menu is Control and not game.is_inside_tree() and session.has_game() and not paused,"Return to MainMenu detaches and retains same bakery")
 for i in 12:await process_frame
 check(game.demand.game_time==clock and game.production.elapsed==elapsed and game.spawner.rng.state==rng_state,"Detached bakery does not advance clock, production or RNG")
 var profile_before:=session.cosmetics.get_save_data()
 menu.shop_button.pressed.emit()
 await process_frame;await process_frame
 shop=current_scene
 check(shop.balance_label.text.contains("25") and shop.manager.wallet==game.progression.crystals,"Earned campaign crystals appear unchanged in shop")
 shop.select_item(&"MIA_MINT");shop.action.pressed.emit()
 check(session.wallet.balance==5 and session.cosmetics.owns(&"MIA_MINT") and shop.action.text=="Применить","Shop purchase commits debit, ownership and UI")
 shop.action.pressed.emit()
 check(session.cosmetics.active("MIA_OUTFIT").id==&"MIA_MINT" and session.wallet.balance==5,"Shop applies bought outfit for free")
 check(game.progression.stats.get_save_data()==stats.stats and game.economy.get_save_data()==economy,"Buying cosmetics cannot alter coins or campaign statistics")
 shop.back()
 await process_frame;await process_frame
 menu=current_scene
 start=menu.find_children("*","Button",true,false)[0]
 check(start.text=="Продолжить","MainMenu offers genuine continuation")
 var old_instance:int=game.get_instance_id()
 start.pressed.emit()
 await process_frame;await process_frame
 check(current_scene==game and game.get_instance_id()==old_instance,"Continue restores exact same BakeryGame instance")
 check(game.progression.stats.get_save_data()==stats.stats and game.economy.get_save_data()==economy and session.wallet.balance==5,"Continuation preserves economy, progress and spent crystals")
 check(game.campaign_view.gems_label.text.contains("5"),"Campaign HUD refreshes spent crystal balance on continuation")
 check(mesh_colors(game.mia.visual).has(CosmeticCatalog.find(&"MIA_MINT").style.secondary),"Returned Mia wears selected mint apron")
 var rewards_before:=game.progression.rewards.claimed.duplicate()
 game.progression.refresh()
 check(game.progression.rewards.claimed==rewards_before and session.wallet.balance==5,"Returning and refreshing cannot repeat campaign rewards")
 # Use a separate fixture wallet for visual invariance; player session is never funded.
 var visual_wallet:=CrystalWallet.new();visual_wallet.grant_once("visual-fixture",300)
 var wardrobe:=CosmeticManager.new(visual_wallet)
 for id in [&"MIA_LAVENDER",&"INTERIOR_GOLD",&"DESSERT_FESTIVE"]:wardrobe.purchase(id);wardrobe.equip(id)
 var physical_count:int=game.find_children("*","CollisionShape3D",true,false).size()
 var transform_before:Transform3D=game.mia.transform
 var feature_before:=game.demand.features()
 var stations_before:Dictionary=game.capture_rush_state().stations
 var actual_style:CosmeticStyle=BakeryVisuals.dessert_style
 BakeryVisuals.dessert_style=wardrobe.active("DESSERT_STYLE").style
 game.apply_cosmetics(wardrobe)
 check(physical_count==game.find_children("*","CollisionShape3D",true,false).size() and game.mia.transform==transform_before,"All cosmetics leave collision count and gameplay transforms unchanged")
 check(game.capture_rush_state().stations==stations_before and game.demand.features()==feature_before,"Production settings, products and ML features unchanged by all styles")
 check(game.mia.visual.head.has_node("CosmeticHatBand") and game.interior.decor.get_node("CosmeticDecor").get_child_count()>0,"Lavender outfit and gold interior include decorative geometry")
 game.personnel.operation_allowed=Callable();game.personnel.hire(&"COFFEE")
 game.development.operation_allowed=Callable();game.development.buy(&"CUPCAKE")
 game.zones.unlock_zone3_for_campaign(true)
 game.apply_cosmetics(wardrobe)
 check(mesh_colors(game.zone_visuals[3]).has(wardrobe.active("INTERIOR_THEME").style.primary),"Newly opened third zone accepts selected theme")
 var node:=Node3D.new();root.add_child(node)
 for product in ProductCatalog.all():BakeryVisuals.product(node,Vector3.ZERO,product.id,wardrobe.active("DESSERT_STYLE").style)
 var same_product:=CosmeticProductVisual.build(node,Vector3.ZERO,&"CAKE",wardrobe.active("DESSERT_STYLE").style)
 check(node.get_child(3).get_child(0).mesh==same_product.get_child(0).mesh,"Repeated decorated products share cached merged mesh")
 node.remove_child(same_product);same_product.queue_free()
 check(node.get_child_count()==4 and node.get_child(3).get_meta("cosmetic_product_id")==&"CAKE","Four dessert identities retained with decorative models")
 node.queue_free()
 BakeryVisuals.dessert_style=actual_style
 game.apply_cosmetics(session.cosmetics)
 check(game.mia.visual.state in [&"Idle",&"Walk",&"CarryIdle",&"CarryWalk"] or game.mia.visual.interaction_time>0,"Outfit application preserves animation controller")
 # Session serialization validates before mutation and refuses a live-world overwrite.
 var profile:=session.get_save_data()
 check(not session.load_save_data(profile),"Profile load cannot overwrite an active bakery")
 check(not session.cosmetics.load_save_data({"version":1,"owned":["UNKNOWN"],"active":{}}),"Unknown profile cannot corrupt current wardrobe")
 # Checkpoint spending policy without awarding or spending provisional gems.
 var runtime:=game.progression
 runtime.rush.checkpoint=runtime.capture_checkpoint()
 runtime.rush.active=true
 session.wallet.grant_once("trial-provisional",30)
 check(session.spendable_crystals()==5 and not session.cosmetics.purchase(&"INTERIOR_MINT"),"Provisional Rush crystals cannot fund permanent cosmetics")
 runtime.rush.active=false
 session.wallet.load_save_data(profile.wallet)
 # A confirmed-balance trial purchase must survive a failed trial restore.
 var baseline_wallet:=session.wallet.get_save_data()
 session.wallet.grant_once("checkpoint-fixture",60)
 runtime.rush.checkpoint=runtime.capture_checkpoint();runtime.rush.active=true
 check(session.cosmetics.purchase(&"INTERIOR_MINT") and session.wallet.balance==35,"Confirmed crystals can buy during an active trial")
 var checkpoint:=runtime.rush.checkpoint.duplicate(true)
 runtime.rush.active=false
 runtime.restore_checkpoint(checkpoint)
 check(session.wallet.balance==35 and session.cosmetics.owns(&"INTERIOR_MINT") and not session.cosmetics.purchase(&"INTERIOR_MINT"),"Failed-trial restore keeps permanent purchase and debit without duplication")
 # Detach again to ensure no duplicate input/button connections on reentry.
 game.hud_view.pause_buttons[1].pressed.emit()
 await process_frame;await process_frame
 menu=current_scene
 session.start_or_continue()
 await process_frame;await process_frame
 check(current_scene==game and game.hud_view.pause_buttons[1].pressed.get_connections().size()==2,"Repeated scene roundtrip does not rerun ready or duplicate handlers")
 runtime.campaign.won=true;runtime.campaign.stage=3
 game.show_victory()
 var victory:Control=game.campaign_view.victory_screen
 victory.main_menu_requested.emit()
 await process_frame;await process_frame
 check(current_scene is Control and not game.is_inside_tree() and not paused,"Victory can visit main menu with completed bakery retained")
 menu=current_scene;menu.shop_button.pressed.emit()
 await process_frame;await process_frame
 shop=current_scene
 shop.select_item(&"MIA_CLASSIC");shop.perform_action();shop.back()
 await process_frame;await process_frame
 session.start_or_continue()
 await process_frame;await process_frame
 check(current_scene==game and paused and game.modal_kind==&"victory" and game.campaign_view.victory_screen==victory,"Continue preserves victory overlay after shop rather than starting campaign")
 var reward_count:int=runtime.rewards.claimed.size()
 victory.continue_requested.emit()
 await process_frame
 check(runtime.campaign.endless and not paused and runtime.rewards.claimed.size()==reward_count,"Same bakery enters endless without repeating awards after shopping")
 game.queue_free()
 session.active_game=null
 await process_frame
 print("STAGE5_RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
