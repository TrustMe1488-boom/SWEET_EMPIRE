extends SceneTree
var passed := 0
var failed := 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("MENU_SETTINGS ","PASS: " if ok else "FAIL: ",title)
func _initialize():run.call_deferred()
func run():
 var session: GameSessionManager = root.get_node("GameSession")
 var menu: Control = load("res://scenes/main_menu.tscn").instantiate()
 root.add_child(menu);current_scene=menu;await process_frame
 var new_button: Button = menu.find_child("NewGameButton",true,false)
 var continue_button: Button = menu.find_child("ContinueButton",true,false)
 var settings_button: Button = menu.find_child("SettingsButton",true,false)
 check(new_button!=null and continue_button.disabled and settings_button!=null and menu.find_child("ShopButton",true,false)!=null,"First launch offers new game, disabled continue, shop and settings")
 settings_button.pressed.emit();await process_frame
 var sliders:=menu.find_children("*","HSlider",true,false)
 check(sliders.size()==3,"Settings provide master, music and effects")
 sliders[0].value=0.42
 check(is_equal_approx(float(session.settings.master),0.42),"Master volume updates live setting")
 var fixture := {"fixture":"existing"}
 check(session.save_store.write_data(fixture),"Create isolated existing save fixture")
 session.wallet.grant_once("old-reward",100)
 check(session.cosmetics.purchase(&"MIA_MINT"),"Create old purchased cosmetics")
 var old_profile:=session.get_save_data()
 new_button.pressed.emit();await process_frame
 var dialogs:=menu.find_children("*","ConfirmationDialog",true,false)
 var dialog: ConfirmationDialog=dialogs[0]
 check(dialog.visible,"Existing save requests confirmation")
 dialog.hide();await process_frame
 check(session.get_save_data()==old_profile and session.save_store.load_data()==fixture,"Cancel leaves existing progress untouched")
 dialog.confirmed.emit()
 for i in 5:await process_frame
 check(current_scene is BakeryGame and session.has_game(),"Confirmed new game starts bakery")
 var game: BakeryGame = current_scene
 check(game.economy.coins==0 and game.rating.value==4.0 and game.development.stations.size()==1 and game.production.has_cook,"New game uses authored economy, rating and equipment")
 check(game.progression.tutorial.step==0 and session.wallet.balance==0 and not session.cosmetics.owns(&"MIA_MINT"),"New game resets tutorial, crystals and purchases")
 var archived := false
 for name in DirAccess.get_files_at(session.save_store.directory):
  if name.begins_with("save.before-new-"): archived = true
 check(archived,"Previous save is archived")
 game.queue_free();await process_frame
 print("MENU_SETTINGS_RESULT: %d passed, %d failed"%[passed,failed]);quit(0 if failed==0 else 1)
