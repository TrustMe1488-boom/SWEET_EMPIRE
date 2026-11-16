class_name DemandDataCollector
extends Node
const IDS = ["COOKIE", "COFFEE", "CUPCAKE", "CAKE"]
const MAX_RECORDS: int = 8192
var game: Node
var game_time: float = 0
var records: Array = []
var history: Array = []
var restored: bool = false
func _process(delta: float):
 advance(delta)
func advance(delta: float):
 game_time += maxf(0, delta)
 while not history.is_empty() and float(history[0].time) < game_time - 120:
  history.pop_front()
func context() -> Dictionary:
 var available: Array = []
 for product in game.development.orderable_products(): available.append(str(product.id))
 return {"rating":game.rating.value, "chapter":game.progression.campaign.stage if game.progression != null else 1, "available":available, "rush":game.spawner.rush_mode}
func record(kind: String, data: Dictionary):
 var row := context()
 row.merge(data, true)
 if row.has("product_id"): row["product"] = str(row.product_id)
 if data.has("customer_id"):
  for customer in game.queue.customers:
   if customer.customer_id == int(data.customer_id):
    row["product"] = str(customer.order.product_id)
    row["customer_type"] = customer.customer_type
 row["event"] = kind
 row["time"] = game_time
 records.append(row)
 if records.size() > MAX_RECORDS: records.pop_front()
 if kind == "OrderCreated":
  history.append(row.duplicate(true))
  if history.size() > MAX_RECORDS: history.pop_front()
func features() -> Array:
 var state := context()
 var result: Array = [state.rating, state.chapter]
 for id in IDS: result.append(1.0 if id in state.available else 0.0)
 result.append(1.0 if state.rush else 0.0)
 var counts := [0.0,0.0,0.0,0.0]
 var recent: float = 0
 var valid_count: float = 0
 var types := {"NORMAL":0.0,"IMPATIENT":0.0,"SWEET_TOOTH":0.0}
 for row in history:
  var age: float = game_time - float(row.time)
  if age < 0 or age > 120: continue
  valid_count += 1
  var index: int = IDS.find(str(row.product))
  if index >= 0: counts[index] += 1
  if age <= 30: recent += 1
  types[str(row.customer_type)] += 1
 result.append_array(counts)
 result.append(recent)
 result.append(valid_count / minf(120, maxf(30, game_time)))
 for type in ["NORMAL","IMPATIENT","SWEET_TOOTH"]: result.append(types[type] / maxf(1, valid_count))
 result.append(game_time)
 var available: Array[ProductDefinition] = game.development.orderable_products()
 var ai: CustomerUtilityAI = game.utility_ai
 var opportunities := [0.0,0.0,0.0,0.0]
 var interval: float = 3.5 if state.rush else 9.0 / clampf(1 + 0.1 * (float(state.rating) - 4),0.7,1.1)
 for type in ai.config.types:
  var weights := ai.probabilities(available, type, state.rush)
  var all_weights:=ai.probabilities(ProductCatalog.all(),type,state.rush)
  for i in available.size():
   var index: int = IDS.find(str(available[i].id))
   opportunities[index] += float(ai.config.types[type].share) * (0.8*weights[i]+0.2*all_weights[index]) * 120.0 / interval
 result.append_array(opportunities)
 for kind in ["PotentialDemand","MissedPotentialDemand"]:
  var values:Array=[0.0,0.0,0.0,0.0]
  for row in records:
   if row.event!=kind or float(row.time)>game_time or float(row.time)<game_time-120:continue
   var index:int=IDS.find(str(row.get("product","")))
   if index>=0:values[index]+=1
  result.append_array(values)
 return result
func export_csv(path: String) -> Error:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if file == null: return FileAccess.get_open_error()
 file.store_csv_line(PackedStringArray(["time","event","customer_id","customer_type","product","rating","chapter","available","rush"]))
 for row in records:
  var values := PackedStringArray()
  for key in ["time","event","customer_id","customer_type","product","rating","chapter","available","rush"]: values.append(str(row.get(key,"")))
  file.store_csv_line(values)
 return OK
func get_save_data() -> Dictionary:
 return {"time":game_time,"records":records.duplicate(true),"history":history.duplicate(true)}
func load_save_data(data: Dictionary):
 game_time = float(data.time)
 records = data.records.duplicate(true)
 if records.size() > MAX_RECORDS: records = records.slice(records.size() - MAX_RECORDS)
 history = data.history.duplicate(true)
 if history.size() > MAX_RECORDS: history = history.slice(history.size() - MAX_RECORDS)
 restored = true
