class_name RushHourController
extends Node
signal finished(success: bool)
var runtime: Node
var active: bool = false
var won: bool = false
var remaining: float = 90.0
var served: int = 0
var served_ids: Dictionary = {}
var checkpoint: Dictionary = {}
var last_result: String = ""
func start(confirmed: bool) -> bool:
 if not confirmed or active or won or not runtime.campaign.can_start_rush(runtime.stats): return false
 checkpoint = runtime.capture_checkpoint()
 active = true
 remaining = 90.0
 served = 0
 served_ids.clear()
 last_result = ""
 runtime.game.spawner.rush_mode = true
 runtime.game.spawner.remaining = runtime.game.spawner.next_interval()
 for customer in runtime.game.queue.customers:
  if not customer.patience_protected:
   customer.patience += customer.base_patience * 0.2
   customer.patience_limit = customer.base_patience * 1.2
 runtime.changed.emit()
 return true
func record_service(id: int):
 if not active or served_ids.has(str(id)): return
 served_ids[str(id)] = true
 served += 1
 if served >= 15:
  active = false
  won = true
  last_result = "success"
  runtime.game.spawner.rush_mode = false
  runtime.game.spawner.remaining = runtime.game.spawner.next_interval()
  runtime.events.publish(&"RushHourCompleted", {"served":served}, "final_rush")
  finished.emit(true)
func _process(delta: float):
 advance(delta)
func advance(delta: float):
 if not active or delta <= 0: return
 remaining = maxf(0, remaining - delta)
 if remaining <= 0:
  active = false
  runtime.game.get_tree().paused = true
  runtime.restore_checkpoint(checkpoint)
  last_result = "failed"
  finished.emit(false)
