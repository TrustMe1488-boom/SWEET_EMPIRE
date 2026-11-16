class_name QuestManager
extends RefCounted
var rewards: RewardService
var records: Dictionary = {}
func _init(service: RewardService):
 rewards = service
 for quest in CampaignDefinitions.QUESTS: records[quest.id] = {"active":false, "complete":false, "progress":0}
func note_event(kind: StringName, _data: Dictionary):
 var streak: Dictionary = records.q3_streak
 if streak.active and not streak.complete:
  if kind == &"CustomerServed": streak.progress += 1
  elif kind == &"CustomerLeft": streak.progress = 0
func evaluate(stats: ProgressTracker, stage: int):
 for quest in CampaignDefinitions.QUESTS:
  var record: Dictionary = records[quest.id]
  if quest.stage <= stage: record.active = true
  if not record.active or record.complete: continue
  if quest.metric != "stage_streak": record.progress = mini(quest.target, int(stats.amount(quest.metric, quest.get("product", ""))))
  if record.progress >= quest.target:
   record.complete = true
   record.progress = quest.target
   rewards.grant("quest:" + quest.id, "Задание: " + quest.title, quest.coins, quest.gems)
func get_save_data() -> Dictionary:
 return {"version":1, "records":records.duplicate(true)}
func load_save_data(data: Dictionary) -> bool:
 if data.get("version") != 1 or not data.get("records", null) is Dictionary: return false
 for quest in CampaignDefinitions.QUESTS:
  if not data.records.has(quest.id): return false
  var record = data.records[quest.id]
  if not record is Dictionary: return false
  var value = record.get("progress")
  if not (value is int or value is float) or not is_finite(float(value)) or float(value)!=floorf(float(value)): return false
  if not record.get("complete") is bool or not record.get("active") is bool: return false
  if record.complete != (int(value) == quest.target): return false
  if not record is Dictionary or int(record.get("progress", -1)) < 0 or int(record.progress) > quest.target: return false
 records = data.records.duplicate(true)
 return true
