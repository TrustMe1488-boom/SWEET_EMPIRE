class_name CashierController
extends Node
signal customer_served(customer: CustomerController)
var queue: QueueManager
var stock: CheckoutInventory
var economy: EconomySystem
var rating: RatingSystem
var current: CustomerController
var elapsed: float = 0.0
func _physics_process(delta: float):
 advance(delta)
func advance(delta: float):
 if current == null:
  var customer := queue.first()
  if customer == null or customer.state != CustomerController.State.Waiting or stock.amount_for(customer.order.product_id) == 0: return
  current = customer
  current.state = CustomerController.State.Serving
  elapsed = 0.0
 elapsed += delta
 if elapsed >= 2.0:
  if SaleProcessor.complete(current, stock, economy, rating):
   customer_served.emit(current)
   current.leave()
  elif not current.purchased: current.state = CustomerController.State.Waiting
  current = null
  elapsed = 0.0
