extends SceneTree
var passed:int=0
var failed:int=0
func _initialize():run.call_deferred()
func check(ok:bool,title:String):
 if ok:passed+=1
 else:failed+=1
 print("STAGE55_ECON ","PASS " if ok else "FAIL ",title)
func run():
 var stock:=CheckoutInventory.new()
 for product in ProductCatalog.all():
  check(stock.add(100,product.id)==stock.limit_for(product.id),"Independent cap "+str(product.id))
  check(stock.space_for(product.id)==0,"No overflow "+str(product.id))
 var tray:=TrayInventory.new();tray.capacity=12
 for product in ProductCatalog.all():tray.add(3,product.id)
 var total:int=tray.count+stock.count
 check(DeliveryService.deliver(tray,stock)==0 and tray.count==12,"Full mixed checkout keeps all goods on tray")
 stock.take(2,&"COOKIE");stock.take(1,&"CAKE");total-=3
 var observed:Array=[]
 stock.changed.connect(func():observed.append(tray.amount_for(&"COOKIE")==1 and tray.amount_for(&"CAKE")==2))
 check(DeliveryService.deliver(tray,stock)==3 and observed.all(func(x):return x),"Partial mixed transfer is committed before signals")
 check(tray.count+stock.count==total and tray.amount_for(&"COFFEE")==3,"Partial delivery conserves every item")
 var money:=EconomySystem.new();var upgrades:=CheckoutUpgradeManager.new(stock,money)
 check(not upgrades.upgrade() and upgrades.level==1,"Insufficient coins do not upgrade")
 money.grant_reward("fixture",950)
 check(upgrades.upgrade(1) and money.coins==700 and stock.limit_for(&"CAKE")==5,"Level2 costs250 and updates all limits")
 check(not upgrades.upgrade(1) and money.coins==700,"Stale repeated upgrade does not debit")
 check(upgrades.upgrade(2) and money.coins==0 and stock.limit_for(&"COOKIE")==16,"Level3 costs700")
 check(not upgrades.upgrade() and upgrades.level==3,"Maximum level enforced")
 var before:=stock.get_save_data()
 var clone:=CheckoutInventory.new()
 check(clone.load_save_data(JSON.parse_string(JSON.stringify(before))) and clone.get_save_data()==before,"Limited inventory JSON roundtrip")
 var invalid:=before.duplicate(true);invalid.items.COOKIE=100
 check(not clone.load_save_data(invalid) and clone.get_save_data()==before,"Invalid overflow save rejected atomically")
 invalid=before.duplicate(true);invalid.items.CAKE=-1
 check(not clone.load_save_data(invalid),"Negative stock rejected")
 var queue:=QueueManager.new()
 var customer:=CustomerController.new();customer.queue=queue;customer.assign_order(CustomerOrder.new(&"COFFEE"));queue.join(customer);customer.state=CustomerController.State.Waiting
 var second:=CustomerController.new();second.queue=queue;second.assign_order(CustomerOrder.new(&"COOKIE"));queue.join(second);second.state=CustomerController.State.Waiting
 var cashier:=CashierController.new();cashier.queue=queue;cashier.stock=CheckoutInventory.new();cashier.economy=EconomySystem.new();cashier.rating=RatingSystem.new()
 cashier.stock.add(1,&"COOKIE");cashier.advance(2)
 check(not customer.purchased and not second.purchased and cashier.economy.coins==0,"Missing coffee blocks FIFO without substitution")
 customer.advance(3);cashier.stock.add(1,&"COFFEE");cashier.advance(2)
 check(customer.purchased and cashier.economy.coins==20 and cashier.stock.amount_for(&"COFFEE")==0,"Delivery before timeout serves exact product for20 coins")
 cashier.advance(2)
 check(second.purchased and cashier.economy.coins==30,"FIFO resumes after first order")
 customer.free();second.free();cashier.free()
 var game:BakeryGame=load("res://scenes/bakery_game.tscn").instantiate();root.add_child(game)
 await process_frame
 check(game.checkout_upgrades!=null and game.hud_view.stock_label.text.contains("0/8"),"Game and HUD expose limited checkout")
 game.toggle_management(&"development")
 check(paused and game.management_menu.checkout_button.visible,"Development upgrades work in paused menu")
 game.set_paused(false);game.queue_free();await process_frame
 print("STAGE55_ECON_RESULT: %d passed, %d failed"%[passed,failed]);quit(1 if failed else 0)
