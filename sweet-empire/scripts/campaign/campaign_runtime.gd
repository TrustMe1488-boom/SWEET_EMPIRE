class_name CampaignRuntime
extends Node
signal changed
var game: Node
var events: GameEvents
var stats := ProgressTracker.new()
var tutorial := TutorialManager.new()
var crystals := CrystalWallet.new()
var rewards: RewardService
var campaign: CampaignManager
var repeatable:RepeatableQuestManager
var quests: QuestManager
var achievements: AchievementManager
var tray_upgrades: TrayUpgradeManager
var rush: RushHourController
var suspended: bool = false
var _refreshing: bool = false
func configure(owner_game: Node, bus: GameEvents):
 game = owner_game
 events = bus
 repeatable=RepeatableQuestManager.new(crystals,game.development.orderable_products)
 repeatable.sequence_provider=func():return events.sequence
 repeatable.paused_check=func():return game.get_tree()!=null and game.get_tree().paused
 rewards = RewardService.new(game.economy, crystals)
 campaign = CampaignManager.new(rewards)
 quests = QuestManager.new(rewards)
 achievements = AchievementManager.new(rewards)
 tray_upgrades = TrayUpgradeManager.new(game.tray, game.economy)
 tray_upgrades.allowed = operations_allowed
 rush = RushHourController.new()
 rush.runtime = self
 add_child(rush)
 events.occurred.connect(receive)
 tutorial.changed.connect(refresh)
 campaign.stage_completed.connect(_stage_completed)
 campaign.victory.connect(func(): game.show_victory.call_deferred())
 tray_upgrades.upgraded.connect(func(level): events.publish(&"TrayUpgraded", {"level":level}, "tray:%d" % level))
 game.development.operation_allowed = operations_allowed
 game.personnel.operation_allowed = operations_allowed
func operations_allowed() -> bool:
 return tutorial.done and not rush.active
func receive(kind: StringName, data: Dictionary):
 if suspended: return
 repeatable.receive(kind,data)
 quests.note_event(kind, data)
 stats.receive(kind, data)
 refresh()
 if kind == &"CustomerServed": rush.record_service(int(data.customer_id))
func refresh():
 if suspended or _refreshing: return
 _refreshing = true
 if campaign.endless:repeatable.activate()
 tutorial.evaluate(stats)
 campaign.evaluate(stats, tutorial)
 quests.evaluate(stats, campaign.stage)
 achievements.evaluate(stats, campaign)
 _refreshing = false
 changed.emit()
func _stage_completed(stage: int):
 if stage == 2: game.zones.unlock_zone3_for_campaign(true)
func get_save_data() -> Dictionary:
 return {"version":1, "repeatable":repeatable.get_save_data(), "stats":stats.get_save_data(), "tutorial":tutorial.get_save_data(), "campaign":campaign.get_save_data(), "quests":quests.get_save_data(), "achievements":achievements.get_save_data(), "crystals":crystals.get_save_data(), "tray":tray_upgrades.get_save_data(), "rewards":rewards.get_save_data(), "events":events.get_save_data(), "rush_won":rush.won}
func validate_save_data(data: Dictionary) -> bool:
 if data.get("version") != 1: return false
 for key in ["stats", "tutorial", "campaign", "quests", "achievements", "crystals", "tray", "rewards", "events"]:
  if not data.get(key, null) is Dictionary: return false
 var schema: Dictionary = ProgressTracker.new().data
 for key in schema:
  if not data.stats.has(key): return false
  if schema[key] is Dictionary and not data.stats[key] is Dictionary: return false
  if schema[key] is bool and not data.stats[key] is bool: return false
  if schema[key] is int or schema[key] is float:
   if not (data.stats[key] is int or data.stats[key] is float) or not is_finite(float(data.stats[key])) or float(data.stats[key]) < 0: return false
   if schema[key] is int and float(data.stats[key]) != floorf(float(data.stats[key])): return false
  if schema[key] is Dictionary:
   for id in data.stats[key]:
    if not id is String: return false
    var value = data.stats[key][id]
    if key in ["produced","picked","delivered","sold"]:
     if ProductCatalog.find(StringName(id)) == null or not (value is int or value is float): return false
     if not is_finite(float(value)) or float(value) < 0 or float(value) != floorf(float(value)): return false
    elif not value is bool: return false
 for key in ["deliveries", "served", "sales_income", "left", "streak", "best_streak", "upgrades"]:
  if not data.stats[key] is float and not data.stats[key] is int: return false
  if float(data.stats[key]) < 0: return false
 if float(data.stats.rating)<1 or float(data.stats.rating)>5 or float(data.stats.max_rating)<1 or float(data.stats.max_rating)>5: return false
 # Validate all manager schemas against independent temporary instances first.
 var validation_wallet := CrystalWallet.new()
 var validation_reward := RewardService.new(EconomySystem.new(), validation_wallet)
 var validation_tray := TrayInventory.new()
 var validator := TrayUpgradeManager.new(validation_tray, validation_reward.economy)
 if not data.get("rush_won", false) is bool: return false
 if not data.events.get("seen") is Dictionary: return false
 var sequence = data.events.get("sequence")
 if not (sequence is int or sequence is float) or not is_finite(float(sequence)) or float(sequence) < 0 or float(sequence) != floorf(float(sequence)): return false
 for key in data.events.seen:
  if not key is String or data.events.seen[key] != true: return false
 for key in data.rewards:
  if not key is String or data.rewards[key] != true: return false
 if data.has("repeatable"):
  if not data.repeatable is Dictionary: return false
  var available: Callable = game.development.orderable_products if game != null else ProductCatalog.all
  var validation_repeatable := RepeatableQuestManager.new(validation_wallet, available)
  if not validation_repeatable.load_save_data(data.repeatable): return false
 if not validation_wallet.load_save_data(data.crystals) or not TutorialManager.new().load_save_data(data.tutorial) or not CampaignManager.new(validation_reward).load_save_data(data.campaign) or not QuestManager.new(validation_reward).load_save_data(data.quests) or not AchievementManager.new(validation_reward).load_save_data(data.achievements) or not validator.load_save_data(data.tray): return false
 if game != null and TrayUpgradeManager.CAPACITIES[int(data.tray.level) - 1] < game.tray.count: return false
 return true
func load_save_data(data: Dictionary) -> bool:
 if not validate_save_data(data): return false
 suspended = true
 stats.load_save_data(data.stats)
 tutorial.load_save_data(data.tutorial)
 campaign.load_save_data(data.campaign)
 quests.load_save_data(data.quests)
 achievements.load_save_data(data.achievements)
 crystals.load_save_data(data.crystals)
 if data.has("repeatable"):repeatable.load_save_data(data.repeatable)
 tray_upgrades.load_save_data(data.tray)
 rewards.load_save_data(data.rewards)
 events.load_save_data(data.events)
 rush.won = bool(data.get("rush_won", false))
 suspended = false
 changed.emit()
 return true
func capture_checkpoint() -> Dictionary:
 return {"world":game.capture_rush_state(), "progression":get_save_data()}
func restore_checkpoint(data: Dictionary):
 suspended = true
 game.restore_rush_state(data.world)
 load_save_data(data.progression)
 suspended = false
 game.update_hud()
 changed.emit()
