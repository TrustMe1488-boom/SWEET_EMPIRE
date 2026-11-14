class_name DeliveryService
extends RefCounted
static func deliver(tray: ItemInventory, checkout: ItemInventory) -> int:
 return tray.transfer_to(checkout)
