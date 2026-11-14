class_name ZoneManager
extends RefCounted
signal opened(zone: int)
var _open: Dictionary = {1: true}
func is_open(zone: int) -> bool:
 return _open.get(zone, false)
func open_zone2() -> bool:
 return _unlock(2)
func unlock_zone3_for_testing() -> bool:
 # Debug-only API, deliberately absent from every player-facing menu and input map.
 if not OS.has_feature("debug") or not is_open(2): return false
 return _unlock(3)
func _unlock(zone: int) -> bool:
 if is_open(zone): return false
 _open[zone] = true
 opened.emit(zone)
 return true
func highest_open() -> int:
 return 3 if is_open(3) else (2 if is_open(2) else 1)

func unlock_zone3_for_campaign(stage_two_completed: bool) -> bool:
 if not stage_two_completed or not is_open(2): return false
 return _unlock(3)
