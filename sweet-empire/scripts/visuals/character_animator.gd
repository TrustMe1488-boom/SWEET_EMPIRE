extends Node
# Presentation only: never moves GameplayRoot or commits an inventory transaction.
func _process(delta: float):
 get_parent().animate(delta)
