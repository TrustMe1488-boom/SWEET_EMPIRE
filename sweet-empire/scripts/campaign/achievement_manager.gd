class_name AchievementManager
extends RefCounted
var rewards: RewardService
var unlocked: Dictionary = {}
func _init(service: RewardService):
 rewards = service
func evaluate(stats: ProgressTracker, campaign: CampaignManager):
 var checks := [stats.amount("sales_income") > 0, stats.amount("deliveries") >= 20, stats.amount("served") >= 50, stats.data.owned.size() >= 4, stats.amount("max_rating") >= 5.0 - 0.00001, campaign.won]
 for i in checks.size():
  var achievement: Dictionary = CampaignDefinitions.ACHIEVEMENTS[i]
  if checks[i] and not unlocked.has(achievement.id):
   unlocked[achievement.id] = true
   rewards.grant("achievement:" + achievement.id, "Достижение: " + achievement.title, 0, achievement.gems)
func get_save_data() -> Dictionary:
 return {"version":1, "unlocked":unlocked.duplicate()}
func load_save_data(data: Dictionary) -> bool:
 if data.get("version") != 1 or not data.get("unlocked", null) is Dictionary: return false
 var valid: Array = []
 for achievement in CampaignDefinitions.ACHIEVEMENTS: valid.append(achievement.id)
 for key in data.unlocked:
  if key not in valid or data.unlocked[key] != true: return false
 unlocked = data.unlocked.duplicate()
 return true
