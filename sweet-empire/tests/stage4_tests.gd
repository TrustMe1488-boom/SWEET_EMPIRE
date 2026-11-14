extends SceneTree
var passed: int = 0
var failed: int = 0
func _initialize(): run.call_deferred()
func check(value: bool, title: String):
 if value: passed += 1
 else: failed += 1
 print("STAGE4 ","PASS: " if value else "FAIL: ",title)
func run():
 var ai := CustomerUtilityAI.new()
 var rng := RandomNumberGenerator.new()
 var products := ProductCatalog.all()
 var partial: Array[ProductDefinition] = [products[0],products[2]]
 for type in ["NORMAL","IMPATIENT","SWEET_TOOTH"]:
  var p := ai.probabilities(partial,type)
  check(is_equal_approx(p[0]+p[1],1) and p[0]>=0 and p[1]>=0,"Normalized weights "+type)
  var valid := true
  for i in 200:
   valid = valid and ai.choose(partial,rng,type).product_id in [&"COOKIE",&"CUPCAKE"]
  check(valid,"Only eligible products "+type)
 check(ai.choose([],rng,"NORMAL")==null,"No eligible product means no order")
 var sweet := ai.probabilities(products,"SWEET_TOOTH")
 var impatient := ai.probabilities(products,"IMPATIENT")
 check(sweet[2]>sweet[0] and sweet[3]>sweet[1],"Sweet tooth favours cakes and cupcakes")
 check(impatient[0]>impatient[3],"Impatient favours faster products")
 rng.seed = 12345
 var sequence: Array = []
 for i in 100: sequence.append(ai.choose(products,rng,ai.choose_type(rng),true).product_id)
 rng.seed = 12345
 var same := true
 for i in 100: same = same and sequence[i]==ai.choose(products,rng,ai.choose_type(rng),true).product_id
 check(same,"Seed reproduces type and weighted order selection")
 var original_weights = ai.config.types.NORMAL.weights.duplicate()
 ai.config.types.NORMAL.weights=[-1.0,NAN,0.0,0.0]
 var safe_weights := ai.probabilities(products,"NORMAL")
 check(safe_weights==[0.25,0.25,0.25,0.25],"Invalid and zero weights use safe uniform probabilities")
 ai.config.types.NORMAL.weights=original_weights
 var customer := CustomerController.new()
 check(customer.assign_order(CustomerOrder.new(&"CAKE")) and not customer.assign_order(CustomerOrder.new(&"COOKIE")) and customer.order.product_id==&"CAKE","Customer cannot change chosen order")
 customer.free()
 var predictor := DemandPredictor.new()
 check(predictor.load_model(),"Trained JSON loads with exact schema")
 var vectors = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ai/parity_vectors.json"))
 var max_error: float = 0
 for row in vectors:
  var result := predictor.predict(row.features)
  for i in 4: max_error = maxf(max_error,absf(result[i]-float(row.prediction[i])))
 check(max_error<0.000001,"Python/GDScript parity tolerance 1e-6; max="+str(max_error))
 var feature: Array = vectors[0].features.duplicate()
 for i in 4: feature[2+i]=0.0
 check(predictor.predict(feature)==[0.0,0.0,0.0,0.0],"Unavailable products have zero forecast")
 var bad := FileAccess.open("user://stage4-corrupt.json",FileAccess.WRITE)
 bad.store_string("{broken");bad.close()
 check(not predictor.load_model("user://stage4-corrupt.json"),"Corrupt model safely rejected")
 check(not predictor.load_model("res://missing-demand-model.json"),"Missing model safely rejected")
 feature[2]=1.0
 var cold := predictor.predict(feature)
 check(cold[0]>0 and cold[1]==0,"Fallback with no model remains useful and masks stock")
 var model = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ai/demand_model.json"))
 model.scale[0]=0
 bad=FileAccess.open("user://stage4-corrupt.json",FileAccess.WRITE);bad.store_string(JSON.stringify(model));bad.close()
 check(not predictor.load_model("user://stage4-corrupt.json"),"Zero scaler rejected")
 model.scale[0]=1;model.schema_version=999
 bad=FileAccess.open("user://stage4-corrupt.json",FileAccess.WRITE);bad.store_string(JSON.stringify(model));bad.close()
 check(not predictor.load_model("user://stage4-corrupt.json"),"Incompatible schema rejected")
 predictor.load_model()
 for i in 4: predictor.model.intercepts[i]=-100000
 var nonnegative := true
 for value in predictor.predict(feature): nonnegative=nonnegative and value>=0
 check(nonnegative,"Negative raw regression outputs clamped")
 predictor.free()
 var game: BakeryGame = load("res://scenes/bakery_game.tscn").instantiate()
 game.campaign_enabled=true
 root.add_child(game)
 await process_frame
 game.set_process(false)
 game.demand.set_process(false)
 game.predictor.set_process(false)
 check(game.predictor.source=="ML" and game.demand.features().size()==29,"Live game uses real ML feature contract with no history")
 game.spawn_customer()
 var first := game.queue.first()
 first.advance(300)
 check(first.patience_protected and first.patience_limit==20 and game.rating.value==4,"Protected tutorial customer retains infinite patience")
 check(game.demand.history.size()==1 and game.demand.history[0].product=="COOKIE","Order creation collected before sale")
 first.position=game.queue.slot(first);first.state=CustomerController.State.Waiting
 game.checkout.add(1,&"COOKIE")
 game.cashier.advance(2)
 check(first.purchased and game.economy.coins==10,"Correct product sold once")
 check(not SaleProcessor.complete(first,game.checkout,game.economy,game.rating),"Double sale prevented")
 game.demand.advance(29)
 game.predictor._process(0)
 var timestamp: float=game.predictor.last_update
 game.demand.advance(0.5);game.predictor._process(0)
 check(game.predictor.last_update==timestamp,"Forecast does not refresh early")
 game.demand.advance(0.5);game.predictor._process(0)
 check(game.predictor.last_update>=30,"Forecast refreshes at thirty game seconds")
 game.demand.set_process(true);game.predictor.set_process(true)
 var time_before: float=game.demand.game_time
 game.set_paused(true)
 for i in 4: await process_frame
 check(game.demand.game_time==time_before,"Pause freezes collection clock and prediction interval")
 game.set_paused(false)
 game.demand.set_process(false);game.predictor.set_process(false)
 game.progression.tutorial.step=10
 game.development.operation_allowed=Callable()
 game.personnel.operation_allowed=Callable()
 game.economy.grant_reward("qa_stage4",10000)
 game.development.buy(&"COFFEE")
 check(game.demand.context().available==["COOKIE"],"Purchased unstaffed station excluded")
 game.personnel.hire(&"COFFEE")
 check(game.predictor.forecast[1]>0,"Hiring refreshes forecast immediately")
 game._next_customer_id=4
 var types: Dictionary={}
 var valid_types:=true
 for i in 80:
  game.spawner.rush_mode=(i%2==0)
  game.spawn_customer()
  var c: CustomerController=game.queue.customers.back()
  types[c.customer_type]=true
  valid_types=valid_types and is_equal_approx(c.patience_limit,ai.patience(c.customer_type)*(1.2 if game.spawner.rush_mode else 1.0))
  game.queue.remove(c);game.remove_child(c);c.free()
 check(types.size()==3 and valid_types,"All three live types receive exact base/Rush patience")
 var before := game.capture_rush_state()
 game.demand.advance(50)
 game.demand.record("OrderCreated",{"customer_id":9999,"customer_type":"NORMAL","product":"COOKIE"})
 game.predictor.refresh()
 game.restore_rush_state(before)
 check(game.demand.get_save_data()==before.demand and game.predictor.get_save_data()==before.predictor,"Trial rollback restores telemetry, clock and forecast")
 check(game.demand.export_csv("user://stage4-events.csv")==OK,"Session events export to CSV")
 game.campaign_view.show_journal("analytics")
 check(paused and game.campaign_view.page=="analytics","Sophie analytics opens through existing modal pause")
 game.set_paused(false)
 var advisor := SophieAdvisor.new()
 game.checkout.take(game.checkout.amount_for(&"COOKIE"),&"COOKIE")
 check(advisor.advise(game).begins_with("Запасы") or advisor.advise(game).begins_with("Очередь"),"Advisor labels deterministic warning separately")
 var feature_cases=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ai/feature_vectors.json"))
 game.zones.unlock_zone3_for_campaign(true)
 game.development.buy(&"CUPCAKE")
 game.development.buy(&"CAKE")
 for row in feature_cases:
  game.rating.value=float(row.rating)
  game.progression.campaign.stage=int(row.chapter)
  game.spawner.rush_mode=bool(row.rush)
  for i in 4:
   var station:=game.development.get_station(ProductCatalog.all()[i].id)
   if station != null: station.has_cook=bool(row.available[i])
  game.demand.game_time=float(row.time)
  game.demand.history=[]
  for event in row.events:
   game.demand.history.append({"time":event[0],"product":DemandDataCollector.IDS[int(event[1])],"customer_type":event[2]})
  var actual:=game.demand.features()
  var error:float=0
  for i in actual.size(): error=maxf(error,absf(float(actual[i])-float(row.features[i])))
  check(error<0.000001,"Python/GDScript causal feature parity at time "+str(row.time))
 game.spawner.rush_mode=false
 check(game.predictor.last_update==game.demand.game_time,"Rush completion refreshes forecast immediately")
 game.predictor.model.clear()
 game.predictor.refresh()
 check(game.predictor.source=="fallback","Fallback explicitly labelled, never called ML")
 game.queue_free()
 await process_frame
 print("STAGE4_RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed else 0)
