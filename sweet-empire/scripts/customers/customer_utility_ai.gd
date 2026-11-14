class_name CustomerUtilityAI
extends RefCounted
const CONFIG_PATH = "res://assets/ai/customer_profiles.json"
var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
var customer_type: String = "NORMAL"
func choose_type(rng: RandomNumberGenerator) -> String:
 var roll := rng.randf()
 for type in config.types:
  roll -= float(config.types[type].share)
  if roll <= 0: return type
 return "NORMAL"
func patience(type: String) -> float:
 return float(config.types.get(type, config.types.NORMAL).patience)
func probabilities(available: Array[ProductDefinition], type: String, rush: bool = false) -> Array[float]:
 var result: Array[float] = []
 var total: float = 0
 var profile: Dictionary = config.types.get(type, config.types.NORMAL)
 for product in available:
  var index: int = config.products.find(str(product.id))
  var value: float = float(profile.weights[index]) if index >= 0 else 0.0
  # Rush mildly favours shorter preparation; no stock exclusion or price changes.
  if rush: value *= 1.0 + 0.15 * 4.0 / product.base_time
  if not is_finite(value) or value < 0: value = 0
  result.append(value)
  total += value
 if total <= 0:
  for i in result.size(): result[i] = 1.0 / result.size()
 else:
  for i in result.size(): result[i] /= total
 return result
func choose(available: Array[ProductDefinition], rng: RandomNumberGenerator, type: String, rush: bool = false) -> CustomerOrder:
 if available.is_empty(): return null
 var weights := probabilities(available, type, rush)
 var roll := rng.randf()
 for i in available.size():
  roll -= weights[i]
  if roll <= 0 and weights[i] > 0: return CustomerOrder.new(available[i].id)
 return CustomerOrder.new(available.back().id)
