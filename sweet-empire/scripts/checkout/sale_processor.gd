class_name SaleProcessor
extends RefCounted
static func complete(customer: CustomerController, stock: ItemInventory, economy: EconomySystem, rating: RatingSystem) -> bool:
 if customer.purchased or customer.state != CustomerController.State.Serving or stock.amount_for(customer.order.product_id) < 1: return false
 customer.purchased = true
 stock.take(1, customer.order.product_id)
 economy.record_sale(customer.order.product_id)
 rating.adjust(0.02)
 return true
