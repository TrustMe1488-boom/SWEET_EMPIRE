class_name DemandPredictor
extends Node
signal updated
const FEATURES = ["rating","chapter","available_COOKIE","available_COFFEE","available_CUPCAKE","available_CAKE","rush","orders120_COOKIE","orders120_COFFEE","orders120_CUPCAKE","orders120_CAKE","orders30","arrival_rate","share_NORMAL","share_IMPATIENT","share_SWEET_TOOTH","session_time","opportunity_COOKIE","opportunity_COFFEE","opportunity_CUPCAKE","opportunity_CAKE","potential120_COOKIE","potential120_COFFEE","potential120_CUPCAKE","potential120_CAKE","missed120_COOKIE","missed120_COFFEE","missed120_CUPCAKE","missed120_CAKE"]
var collector: DemandDataCollector
var model: Dictionary = {}
var forecast: Array = [0.0,0.0,0.0,0.0]
var source: String = "fallback"
var last_update: float = -1
var signature: String = ""
func _process(_delta: float):
 if collector == null: return
 var state := collector.context()
 var key := str(state.available) + str(state.rush)
 if key != signature or collector.game_time - last_update >= 30 or collector.restored:
  collector.restored = false
  signature = key
  refresh()
func load_model(path: String = "res://assets/ai/demand_model.json") -> bool:
 model = {}
 if not FileAccess.file_exists(path): return false
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path)) != OK: return false
 var parsed = parser.data
 if not parsed is Dictionary: return false
 if parsed.get("products") != ["COOKIE","COFFEE","CUPCAKE","CAKE"] or parsed.get("horizon_seconds") != 120: return false
 if parsed.get("version") != 1 or parsed.get("schema_version") != 2 or parsed.get("features") != FEATURES: return false
 for key in ["mean","scale"]:
  if not parsed.get(key) is Array or parsed[key].size() != FEATURES.size(): return false
  for value in parsed[key]:
   if not (value is float or value is int) or not is_finite(float(value)): return false
 for value in parsed.scale:
  if float(value) <= 0: return false
 if not parsed.get("coefficients") is Array or parsed.coefficients.size() != 4: return false
 if not parsed.get("intercepts") is Array or parsed.intercepts.size() != 4: return false
 for row in parsed.coefficients:
  if not row is Array or row.size() != FEATURES.size(): return false
  for value in row:
   if not (value is float or value is int) or not is_finite(float(value)): return false
 for value in parsed.intercepts:
  if not (value is float or value is int) or not is_finite(float(value)): return false
 model = parsed
 return true
func predict(features: Array) -> Array:
 var result: Array = [0.0,0.0,0.0,0.0]
 if features.size() != FEATURES.size(): return result
 for value in features:
  if not is_finite(float(value)): return result
 if model.is_empty():
  var total: float = 0
  for i in 4: total += float(features[2+i])
  var interval: float = 3.5 if float(features[6]) > 0 else 9.0 / clampf(1 + 0.1 * (float(features[0]) - 4),0.7,1.1)
  for i in 4: result[i] = 120.0 / interval / maxf(1,total) if float(features[2+i]) > 0 else 0.0
 else:
  for i in 4:
   var value: float = float(model.intercepts[i])
   for j in FEATURES.size(): value += float(model.coefficients[i][j]) * (float(features[j]) - float(model.mean[j])) / float(model.scale[j])
   result[i] = maxf(0,value) if is_finite(value) and float(features[2+i]) > 0 else 0.0
 return result
func refresh():
 if collector == null: return
 var state := collector.context()
 signature = str(state.available) + str(state.rush)
 forecast = predict(collector.features())
 source = "ML" if not model.is_empty() else "fallback"
 last_update = collector.game_time
 updated.emit()
func get_save_data() -> Dictionary:
 return {"forecast":forecast.duplicate(),"last_update":last_update,"signature":signature,"source":source}
func load_save_data(data: Dictionary):
 forecast = data.forecast.duplicate()
 last_update = float(data.last_update)
 signature = str(data.signature)
 source = str(data.source)
