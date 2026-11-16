class_name SophieAdvisor
extends RefCounted
func advise(game: Node) -> String:
 var first: CustomerController = game.queue.first()
 if first != null and game.checkout.amount_for(first.order.product_id) == 0:
  return "Очередь: первый покупатель ждёт «%s»." % ProductCatalog.find(first.order.product_id).display_name
 for product in game.development.orderable_products():
  if game.checkout.amount_for(product.id) == 0:
   return "Запасы: на кассе закончился товар «%s». На подносе: %d." % [product.display_name, game.tray.amount_for(product.id)]
 for product in game.development.orderable_products():
  if game.development.get_station(product.id).inventory.count >= 5:
   return "Производство: станция «%s» заполнена — забери продукцию." % product.display_name
 for i in 4:
  var product: ProductDefinition = ProductCatalog.all()[i]
  if game.predictor.forecast[i] > game.checkout.amount_for(product.id) + game.tray.amount_for(product.id):
   return "Прогноз (%s): подготовь больше товара «%s»." % [game.predictor.source, product.display_name]
 return "Запасы достаточны. Следи за первым заказом и доставляй продукцию вручную."

func priority(game:Node)->Dictionary:
 var remaining:Dictionary=game.checkout.contents()
 var position:int=0
 for customer in game.queue.customers:
  position+=1
  var id:StringName=customer.order.product_id
  if int(remaining.get(id,0))>0:remaining[id]=int(remaining[id])-1;continue
  var station:ProductionStation=game.development.get_station(id)
  return {"product":id,"critical":true,"source":"Подтверждённый заказ","text":"Доставь %s · очередь #%d · %.0f с\nНа станции: %d · поднос: %d"%[ProductCatalog.find(id).display_name,position,customer.patience,station.inventory.count if station!=null else 0,game.tray.amount_for(id)]}
 for product in game.development.orderable_products():
  var station:ProductionStation=game.development.get_station(product.id)
  if game.checkout.amount_for(product.id)<=1:return {"product":product.id,"critical":false,"source":"Низкий запас","text":"Пополнить: "+product.display_name}
  if station.inventory.count==5:return {"product":product.id,"critical":false,"source":"Буфер заполнен","text":"Забери: "+product.display_name}
 return {"product":&"COOKIE","critical":false,"source":"Планирование","text":advise(game)}
func snapshot(game:Node)->Dictionary:
 var confirmed:Dictionary={}
 for customer in game.queue.customers:confirmed[str(customer.order.product_id)]=int(confirmed.get(str(customer.order.product_id),0))+1
 var sales:Dictionary={};var income:int=0
 for operation in game.economy.history:
  if operation.category==&"sale":income+=int(operation.amount);sales[str(operation.subject)]=int(sales.get(str(operation.subject),0))+1
 return {"coins":game.economy.coins,"income":income,"rating":game.rating.value,"sales":sales,"stock":game.checkout.contents(),"confirmed":confirmed,"traffic":game.pedestrians.counts.duplicate(true),"forecast":game.predictor.forecast.duplicate(),"priority":priority(game)}
