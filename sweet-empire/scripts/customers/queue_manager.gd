class_name QueueManager
extends RefCounted
signal changed
var customers: Array[CustomerController] = []
const CAPACITY = 5
func join(customer: CustomerController) -> bool:
 if customers.size() >= CAPACITY or customers.has(customer): return false
 customers.append(customer)
 changed.emit()
 return true
func remove(customer: CustomerController):
 if customers.has(customer):
  customers.erase(customer)
  changed.emit()
func first() -> CustomerController:
 return null if customers.is_empty() else customers[0]
func slot(customer: CustomerController) -> Vector3:
 return Vector3(2.7, 0, 0.7 + customers.find(customer) * 0.9)
