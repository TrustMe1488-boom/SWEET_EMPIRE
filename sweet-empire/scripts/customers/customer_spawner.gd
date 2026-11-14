class_name CustomerSpawner
extends Node
signal spawn_requested
var rating: RatingSystem
var remaining: float = 8.0
signal mode_changed
var rush_mode: bool = false:
 set(value):
  if rush_mode == value: return
  rush_mode = value
  mode_changed.emit()
var rng := RandomNumberGenerator.new()
func _ready():
 rng.randomize()
func next_interval() -> float:
 if rush_mode: return rng.randf_range(3.0, 4.0)
 return rng.randf_range(8.0, 10.0) / rating.spawn_factor()
func _process(delta: float):
 remaining -= delta
 while remaining <= 0:
  spawn_requested.emit()
  remaining += next_interval()
