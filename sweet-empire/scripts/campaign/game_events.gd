class_name GameEvents
extends RefCounted
signal occurred(kind: StringName, data: Dictionary)
var sequence: int = 0
var _seen: Dictionary = {}
func publish(kind: StringName, data: Dictionary = {}, token: String = "") -> bool:
 var key := str(kind) + ":" + token
 if not token.is_empty() and _seen.has(key): return false
 if not token.is_empty(): _seen[key] = true
 sequence += 1
 var payload := data.duplicate(true)
 payload["event_sequence"] = sequence
 occurred.emit(kind, payload)
 return true
func get_save_data() -> Dictionary:
 return {"sequence": sequence, "seen": _seen.duplicate()}
func load_save_data(data: Dictionary):
 sequence = maxi(0, int(data.get("sequence", 0)))
 _seen = data.get("seen", {}).duplicate()
