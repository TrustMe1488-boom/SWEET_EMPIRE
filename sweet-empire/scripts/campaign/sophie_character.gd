class_name SophieCharacter
extends Node3D
var model: ChibiVisual
var talking: bool = false
var greeting: float = 1.2
func _ready():
 model = BakeryVisuals.person(self, BakeryVisuals.MINT, false, Color("#edc1a0"), 0, "sophie")
 model.rotation.y = -2.35
 BakeryVisuals.label(self, Vector3(0, 2.05, 0), "Софи", 23)
func _process(delta: float):
 greeting = maxf(0, greeting - delta)
 model.set_state(&"Greeting" if greeting > 0 else (&"Talking" if talking else &"Idle"))
