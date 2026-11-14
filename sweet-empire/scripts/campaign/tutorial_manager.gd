class_name TutorialManager
extends RefCounted
signal changed
const STEPS = ["Приветствие Софи", "Пройдите немного: WASD", "Подойдите к печи", "Заберите печенье: E", "Подойдите к кассе слева", "Передайте печенье: E", "Дождитесь первой продажи", "Выполните ещё две доставки", "Откройте развитие: 1", "Откройте персонал: 2", "Обучение завершено"]
var step: int = 0
var first_customer_spawned: bool = false
var first_served: bool = false
var done: bool:
 get: return step >= 10
func acknowledge():
 if step == 0:
  step = 1
  changed.emit()
func evaluate(stats: ProgressTracker):
 first_served = stats.amount("served") >= 1
 if step == 0 or done: return
 var checks := [true, stats.amount("movement") >= 1, stats.data.near.get("oven", false), stats.amount("picked", "COOKIE") >= 1, stats.data.near.get("checkout", false), stats.amount("deliveries") >= 1, first_served, stats.amount("deliveries") >= 3, stats.data.menus.get("development", false), stats.data.menus.get("personnel", false)]
 var previous := step
 while step < 10 and checks[step]: step += 1
 if step != previous: changed.emit()
func get_save_data() -> Dictionary:
 return {"version": 1, "step": step, "first_customer_spawned": first_customer_spawned, "first_served": first_served}
func load_save_data(data: Dictionary) -> bool:
 if int(data.get("version", 0)) != 1 or int(data.get("step", -1)) < 0 or int(data.step) > 10: return false
 step = int(data.step)
 first_customer_spawned = bool(data.get("first_customer_spawned", false))
 first_served = bool(data.get("first_served", false))
 return true
