extends SceneTree
var passed:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(ok:bool,title:String):
 if ok:passed+=1
 else:failed+=1
 print("STAGE55_PROGRESS ","PASS " if ok else "FAIL ",title)
func run():
 var wallet:=CrystalWallet.new();var available: Array[ProductDefinition]=[ProductCatalog.find(&"COOKIE")]
 var quests:=RepeatableQuestManager.new(wallet,func():return available)
 var pause:Dictionary={"value":false}
 quests.paused_check=func():return pause.value
 check(quests.records.is_empty() and wallet.balance==0,"No repeatable quests before endless activation")
 quests.activate()
 check(quests.records.size()==3 and quests.records.all(func(r):return r.key!="cakes"),"Three feasible distinct quests, no unavailable cakes")
 var keys:Array=[]
 for row in quests.records:keys.append(row.key)
 check(keys.size()==3 and keys[0]!=keys[1] and keys[1]!=keys[2] and keys[0]!=keys[2],"Concurrent templates differ")
 quests.receive(&"CustomerServed",{"event_sequence":1})
 var snapshot:=quests.get_save_data()
 quests.receive(&"CustomerServed",{"event_sequence":1})
 check(quests.get_save_data()==snapshot,"Duplicate event cannot advance twice")
 pause.value=true;quests.receive(&"CustomerServed",{"event_sequence":2});pause.value=false
 quests.receive(&"CustomerServed",{"event_sequence":2})
 check(quests.records[0].progress==1,"Paused events stay rejected even if replayed after resume")
 for seq in range(3,22):quests.receive(&"CustomerServed",{"event_sequence":seq})
 var completed:Dictionary=quests.records[0]
 check(completed.complete and wallet.balance==0,"Completed quest waits for explicit reward claim")
 var id:String=completed.id
 check(quests.claim(id) and wallet.balance==3 and quests.records.size()==3,"Claim grants3 crystals and immediately replaces slot")
 check(not quests.claim(id) and wallet.balance==3,"Same quest cannot award twice")
 var clone:=RepeatableQuestManager.new(wallet,func():return available)
 check(clone.load_save_data(JSON.parse_string(JSON.stringify(quests.get_save_data()))),"Repeatable progress serializes")
 var before:=clone.get_save_data();clone.receive(&"CustomerServed",{"event_sequence":21})
 check(clone.get_save_data()==before,"JSON roundtrip preserves event deduplication")
 var model:ChibiVisual=load("res://scenes/visuals/chibi_character.tscn").instantiate();model.role="mia";model.clothing=BakeryVisuals.CREAM;root.add_child(model)
 for id_costume in [&"MIA_MAID",&"MIA_ROYAL",&"MIA_WINTER"]:
  model.set_state(&"CarryWalk")
  CosmeticVisualApplicator.apply_outfit(model,CosmeticCatalog.find(id_costume))
  check(model.head.has_node("GeometricCostume") and model.state==&"CarryWalk","Real geometry attached to animated pivots: "+str(id_costume))
 CosmeticVisualApplicator.apply_outfit(model,CosmeticCatalog.find(&"MIA_CLASSIC"))
 check(not model.head.has_node("GeometricCostume"),"Unequipping restores original chef silhouette")
 model.queue_free();await process_frame
 var game:BakeryGame=load("res://scenes/bakery_game.tscn").instantiate();game.campaign_enabled=true;root.add_child(game);await process_frame
 check(game.dashboard!=null and game.dashboard.panel.visible,"Compact Sophie dashboard exists")
 game.open_analytics();check(paused and game.campaign_view.page=="analytics","Full analytics still opens and pauses simulation")
 game.set_paused(false);game.queue_free();await process_frame
 print("STAGE55_PROGRESS_RESULT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
