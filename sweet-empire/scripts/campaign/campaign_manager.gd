class_name CampaignManager
extends RefCounted
signal stage_completed(stage: int)
signal victory
var rewards: RewardService
var stage: int = 1
var completed: Dictionary = {}
var won: bool = false
var endless: bool = false
func _init(service: RewardService):
 rewards = service
func objectives(stats: ProgressTracker, tutorial: TutorialManager) -> Array[Dictionary]:
 match stage:
  1:
   return [_goal("c1_tutorial", "Завершить обучение", tutorial.step, 10), _goal("c1_deliveries", "Доставки", stats.amount("deliveries"), 5), _goal("c1_income", "Заработать продажами", stats.amount("sales_income"), 200), _goal("c1_coffee", "Купить кофемашину", int(stats.data.owned.get("COFFEE", false)), 1)]
  2:
   return [_goal("c2_chef", "Нанять повара кофемашины", int(stats.data.hired.get("COFFEE", false)), 1), _goal("c2_cupcakes", "Купить станцию капкейков", int(stats.data.owned.get("CUPCAKE", false)), 1), _goal("c2_tray", "Поднос: уровень 2", stats.amount("tray_level"), 2), _goal("c2_guests", "Обслужить покупателей", stats.amount("served"), 30)]
  _:
   return [_goal("c3_cake", "Купить станцию тортов", int(stats.data.owned.get("CAKE", false)), 1), _goal("c3_chef", "Нанять повара тортов", int(stats.data.hired.get("CAKE", false)), 1), _goal("c3_guests", "Обслужить покупателей", stats.amount("served"), 100), _goal("c3_rating", "Рейтинг не ниже 4,5", stats.amount("rating"), 4.5), _goal("c3_rush", "Победить в Rush Hour", int(stats.data.rush_success), 1)]
func _goal(id: String, title: String, value: float, target: float) -> Dictionary:
 return {"id":id, "title":title, "progress":target if won else minf(value, target), "target":target, "complete":won or value + 0.00001 >= target}
func evaluate(stats: ProgressTracker, tutorial: TutorialManager):
 if won: return
 for i in 3:
  if not objectives(stats, tutorial).all(func(goal): return goal.complete): return
  var finished := stage
  var id: String = CampaignDefinitions.STAGES[stage - 1]
  if completed.has(id): return
  completed[id] = true
  if stage < 3: stage += 1
  else: won = true
  rewards.grant("campaign:" + id, CampaignDefinitions.TITLES[finished - 1], 0, [10, 20, 50][finished - 1])
  stage_completed.emit(finished)
  if won:
   victory.emit()
   return
func can_start_rush(stats: ProgressTracker) -> bool:
 return stage == 3 and not won and stats.data.owned.get("CAKE", false) and stats.data.hired.get("CAKE", false) and stats.amount("served") >= 100 and stats.amount("rating") >= 4.5
func enter_endless() -> bool:
 if not won: return false
 endless = true
 return true
func get_save_data() -> Dictionary:
 return {"version":1, "stage":stage, "completed":completed.duplicate(), "won":won, "endless":endless}
func load_save_data(data: Dictionary) -> bool:
 if int(data.get("version", 0)) != 1 or int(data.get("stage", 0)) < 1 or int(data.stage) > 3 or not data.get("completed", null) is Dictionary: return false
 if bool(data.get("won", false)) and (not data.completed.get("sweet_empire", false) or int(data.stage) != 3): return false
 if bool(data.get("endless", false)) and not bool(data.get("won", false)): return false
 stage = int(data.stage)
 completed = data.completed.duplicate()
 won = bool(data.get("won", false))
 endless = bool(data.get("endless", false))
 return true
