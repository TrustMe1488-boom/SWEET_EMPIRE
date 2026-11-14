extends SceneTree
var passed:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(ok:bool,title:String):
 if ok:passed+=1
 else:failed+=1
 print("STAGE55_DEMAND ","PASS " if ok else "FAIL ",title)
func run():
 var game:BakeryGame=load("res://scenes/bakery_game.tscn").instantiate();root.add_child(game)
 await process_frame
 game.process_mode=Node.PROCESS_MODE_DISABLED
 var flow:PedestrianManager=game.pedestrians
 game.spawner.rng.seed=55
 flow.request_pedestrian()
 check(flow.visitors.size()==1 and game.queue.customers.is_empty(),"Spawn creates a visible street visitor, not an order")
 var visitor:PedestrianController=flow.visitors[0]
 visitor.desired_product=&"CAKE"
 var rating:float=game.rating.value
 flow.advance(20)
 check(game.queue.customers.is_empty() and game.rating.value==rating and game.economy.coins==0,"Unavailable cake passes without rating or income")
 check(flow.counts.missed.get("CAKE",0)==1 and game.demand.history.is_empty(),"Missed potential demand is separate from confirmed order history")
 flow.advance(20)
 check(flow.visitors.is_empty(),"Passerby walks to street end before despawn")
 flow.request_pedestrian();visitor=flow.visitors[0];visitor.desired_product=&"COOKIE"
 flow.advance(20)
 check(game.queue.customers.size()==1 and flow.visitors.is_empty(),"Visitor physically reaches doorway before FIFO admission")
 var customer:CustomerController=game.queue.first()
 check(customer.order.product_id==&"COOKIE" and game.demand.history.size()==1 and game.checkout.count==0,"Empty checkout does not prevent confirmed cookie order")
 check(customer.has_node("OrderProductIcon") and customer.patience_bar!=null,"Product marker and patience remain visible")
 customer.position=game.queue.slot(customer);customer.state=CustomerController.State.Waiting
 game.cashier.advance(2)
 check(not customer.purchased,"Missing stock waits rather than instantly leaving")
 customer.advance(3);game.checkout.add(1);game.cashier.advance(2)
 check(customer.purchased and game.economy.coins==10,"Timely replenishment serves waiting customer")
 var before:=game.capture_rush_state()
 flow.request_pedestrian();flow.advance(1)
 game.restore_rush_state(before)
 check(flow.get_save_data()==before.pedestrians,"Rush snapshot restores pedestrians, desire, route and traffic metrics")
 flow.request_pedestrian();visitor=flow.visitors[0]
 var position_before:Vector3=visitor.position
 game.process_mode=Node.PROCESS_MODE_INHERIT;game.set_paused(true)
 for i in 5:await process_frame
 check(visitor.position==position_before,"Menus freeze pedestrians")
 game.set_paused(false);game.queue_free();await process_frame
 print("STAGE55_DEMAND_RESULT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
