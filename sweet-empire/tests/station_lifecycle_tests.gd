extends SceneTree
var passed: int = 0
var failed: int = 0
func check(ok: bool, title: String):
 if ok: passed += 1
 else: failed += 1
 print("STATION_LIFECYCLE ","PASS: " if ok else "FAIL: ",title)
func _initialize():run.call_deferred()
func wall_blocked(game: BakeryGame, x: float, from_z: float, to_z: float) -> bool:
 var query := PhysicsRayQueryParameters3D.create(Vector3(x,1,from_z),Vector3(x,1,to_z))
 query.exclude = [game.mia.get_rid()]
 return not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func blocked(game: BakeryGame) -> bool:
 return wall_blocked(game,0,-4.8,-6.2)
func decor_valid(interior: BakeryInterior, stage: int) -> bool:
 if interior.exterior_plants.size()!=2 or interior.stage_lights.size()!=3: return false
 for plant in interior.exterior_plants:
  if not is_equal_approx(plant.position.z,-4.6-5.0*(stage-1)): return false
  if not plant.find_children("*","CollisionObject3D",true,false).is_empty(): return false
  for mesh in plant.find_children("*","MeshInstance3D",true,false):
   if not mesh.visible: return false
 for i in 3:
  if interior.stage_lights[i].visible != (i<stage): return false
  if not interior.stage_lights[i].find_children("*","CollisionObject3D",true,false).is_empty(): return false
 return interior.stage_lights[0].get_child_count()==2 and interior.stage_lights[1].get_child_count()==2 and interior.stage_lights[2].get_child_count()==1
func run():
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled = true
 root.add_child(game);await process_frame;await physics_frame
 var facade := game.interior.exterior_facade
 var facade_parts := facade.get_child_count()
 check(facade.position.z==0 and facade_parts>15 and facade.find_children("*","Label3D",true,false).size()==1,"Stage 1 has one exterior facade on the original wall")
 check(decor_valid(game.interior,1),"Stage 1 plants and original lights retain their layout without collisions")
 check(not game.zones.is_open(2) and not game.station_visuals.has(&"COFFEE"),"New game starts without coffee station or zone 2")
 check(blocked(game),"Closed back wall blocks the unopened passage")
 var initial := GamePersistence.capture(game)
 game.progression.tutorial.step = 10
 game.economy.grant_reward("station-lifecycle-fixture",1000)
 check(game.development.buy(&"COFFEE"),"Coffee purchase succeeds through actual progression")
 await process_frame;await physics_frame;await physics_frame
 check(game.zones.is_open(2) and not blocked(game),"Opening zone disables old wall collision")
 check(facade.position.z == -5.0 and facade.get_child_count()==facade_parts and facade.find_children("*","Label3D",true,false)[0].visible,"Stage 2 moves one visible facade to its exterior wall")
 check(decor_valid(game.interior,2),"Stage 2 plants and lights follow the expanded layout")
 check(not wall_blocked(game,-3,-4.8,-6.2) and not wall_blocked(game,3,-4.8,-6.2),"Stage 2 old partition has no remaining side collisions")
 var old_trim_visible := false
 for node in game.interior.decor.get_children():
  if node is VisualInstance3D and is_equal_approx(node.position.z,-5.25) and node.visible: old_trim_visible = true
 check(not old_trim_visible,"Stage 2 removes obsolete back-wall trim")
 check(game.station_visuals.has(&"COFFEE") and not game.installation_slots.has(&"COFFEE"),"One coffee station and no coffee placeholder")
 check(game.installation_slots.has(&"CUPCAKE") and game.installation_slots[&"CUPCAKE"].find_children("*","CollisionObject3D",true,false).is_empty(),"Unpurchased cupcake marker is visual-only")
 var coffee_station := game.development.get_station(&"COFFEE")
 coffee_station.inventory.add(1,&"COFFEE")
 game.mia.position = coffee_station.product.world_position + Vector3(0,0.05,1.25)
 check(game.nearest_station()==3,"Coffee interaction point selects the purchased station")
 game.interact()
 check(game.tray.amount_for(&"COFFEE")==1,"Interaction picks up coffee without duplication")
 var collision_count := game.interior.collisions.get_child_count()
 var zone_count := game.zone_visuals.size()
 var coffee: Node = game.station_visuals[&"COFFEE"]
 game.on_zone_opened(2);game.interior.open_expansion_passage();game.on_station_purchased(game.development.get_station(&"COFFEE"))
 check(game.interior.collisions.get_child_count()==collision_count and game.zone_visuals.size()==zone_count and game.station_visuals[&"COFFEE"]==coffee,"Repeated callbacks cannot duplicate walls, zone or station")
 var saved := GamePersistence.capture(game)
 var store := SaveStore.new();store.directory="res://.local/station-lifecycle/"+str(Time.get_ticks_usec())
 check(store.write_data(saved),"Save coffee-purchased world to isolated data")
 var restored: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 restored.campaign_enabled=true;restored.process_mode=Node.PROCESS_MODE_DISABLED
 root.add_child(restored);await process_frame
 check(GamePersistence.restore(store.load_data(),restored),"Restore purchased coffee")
 await process_frame;await physics_frame;await physics_frame
 check(restored.station_visuals.has(&"COFFEE") and not restored.installation_slots.has(&"COFFEE") and restored.installation_slots.has(&"CUPCAKE") and restored.interior.exterior_facade.position.z == -5.0 and restored.interior.exterior_facade.get_child_count()==facade_parts and decor_valid(restored.interior,2),"Restore creates coffee once and stage 2 facade and decor")
 var marker: Node = game.installation_slots[&"CUPCAKE"]
 check(game.development.buy(&"CUPCAKE"),"Cupcake purchase succeeds")
 check(not game.installation_slots.has(&"CUPCAKE") and (not is_instance_valid(marker) or not marker.is_inside_tree()),"Purchased cupcake marker leaves scene immediately")
 var physical: Array[Node] = game.station_visuals[&"CUPCAKE"].get_node("CollisionRoot").find_children("*","CollisionShape3D",true,false)
 check(physical.size()==1 and not physical[0].disabled,"Purchased station retains its physical collision")
 var cupcake := game.development.get_station(&"CUPCAKE")
 cupcake.inventory.add(1,&"CUPCAKE")
 game.mia.position = cupcake.product.world_position + Vector3(0,0.05,1.25)
 check(game.nearest_station()==4,"Cupcake interaction point selects its own station")
 game.interact()
 check(game.tray.amount_for(&"CUPCAKE")==1,"Interaction picks up cupcake without conflict")
 var old_wall_query := PhysicsRayQueryParameters3D.create(Vector3(0,1,-9.8),Vector3(0,1,-11.0))
 old_wall_query.exclude = [game.mia.get_rid()]
 check(not game.get_world_3d().direct_space_state.intersect_ray(old_wall_query).is_empty(),"Stage 2 back wall blocks closed stage 3")
 game.economy.grant_reward("stage-three-fixture",2000)
 check(game.zones.unlock_zone3_for_campaign(true),"Stage 3 opens through the existing zone manager")
 await process_frame;await physics_frame;await physics_frame
 check(game.get_world_3d().direct_space_state.intersect_ray(old_wall_query).is_empty(),"Stage 3 removes the old partition collision")
 check(game.zone_visuals[2].back_wall.get_child(0).disabled and not game.zone_visuals[3].back_wall.get_child(0).disabled,"Stage 3 disables the internal wall and retains the exterior wall collision")
 check(facade.position.z == -10.0 and facade.get_child_count()==facade_parts and facade.find_children("*","Label3D",true,false)[0].visible,"Stage 3 moves the same visible facade to the new outside wall")
 check(decor_valid(game.interior,3),"Stage 3 plants and lights follow the final layout")
 check(not wall_blocked(game,-3,-9.8,-11.0) and not wall_blocked(game,3,-9.8,-11.0),"Stage 3 old partition has no remaining side collisions")
 check(game.development.buy(&"CAKE"),"Cake station purchased using existing economy")
 var cake := game.development.get_station(&"CAKE")
 cake.inventory.add(1,&"CAKE")
 game.mia.position = cake.product.world_position + Vector3(0,0.05,1.25)
 check(game.nearest_station()==5,"Cake interaction point selects cake station")
 game.interact()
 check(game.tray.amount_for(&"CAKE")==1 and game.station_visuals.has(&"COFFEE") and game.station_visuals.has(&"CUPCAKE"),"Cake interaction works and previous equipment remains")
 var third_wall_count: int = game.zone_visuals[2].get_node("CollisionRoot").get_child_count()
 game.on_zone_opened(3);game.zone_visuals[2].open_passage();game.on_station_purchased(cake)
 game.interior.set_expansion_stage(3);game.interior.set_expansion_stage(3)
 check(game.zone_visuals.size()==2 and game.zone_visuals[2].get_node("CollisionRoot").get_child_count()==third_wall_count and facade.get_child_count()==facade_parts,"Repeated stage 3 update creates no duplicate walls or facade")
 check(decor_valid(game.interior,3),"Repeated stage update does not duplicate or shift decor")
 var stage_three := GamePersistence.capture(game)
 check(store.write_data(stage_three),"Save stage 3 to isolated data")
 var third: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 third.campaign_enabled=true;third.process_mode=Node.PROCESS_MODE_DISABLED
 root.add_child(third);await process_frame
 check(GamePersistence.restore(store.load_data(),third) and third.zones.highest_open()==3 and third.interior.exterior_facade.position.z == -10.0 and third.interior.exterior_facade.get_child_count()==facade_parts and third.station_visuals.size()==4 and decor_valid(third.interior,3),"Restore stage 3 facade, decor, zones and all four stations")
 var same_facade := facade.get_instance_id()
 root.remove_child(game);root.add_child(game);await process_frame
 check(game.interior.exterior_facade.get_instance_id()==same_facade and facade.position.z == -10.0 and game.station_visuals.size()==4,"Returning same bakery preserves its stage without duplication")
 var before: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 before.campaign_enabled=true;before.process_mode=Node.PROCESS_MODE_DISABLED
 root.add_child(before);await process_frame
 check(GamePersistence.restore(initial,before) and not before.zones.is_open(2) and not before.station_visuals.has(&"COFFEE") and before.interior.exterior_facade.position.z==0 and before.interior.exterior_facade.get_child_count()==facade_parts and decor_valid(before.interior,1),"Restoring pre-purchase save retains stage 1 facade and decor without equipment")
 before.queue_free();restored.queue_free();third.queue_free();game.queue_free();await process_frame
 print("STATION_LIFECYCLE_RESULT: %d passed, %d failed"%[passed,failed]);quit(0 if failed==0 else 1)
