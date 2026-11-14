class_name RatingSystem
extends RefCounted
signal changed
var value: float = 4.0
func adjust(amount: float):
 value = clampf(value + amount, 1.0, 5.0)
 changed.emit()
func spawn_factor() -> float:
 return clampf(1.0 + 0.1 * (value - 4.0), 0.7, 1.1)
