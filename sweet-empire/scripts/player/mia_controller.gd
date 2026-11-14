class_name MiaController
extends CharacterBody3D
signal interaction_requested
signal moved(distance: float)
var input_manager:GameInputManager
var visual: ChibiVisual
var tray_visual: Node3D
var walk_time: float = 0.0
func _ready():
 var collider := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 capsule.radius = 0.27
 capsule.height = 1.5
 collider.shape = capsule
 collider.position.y = 0.75
 add_child(collider)
 collider.name = "CollisionRoot"
 visual = BakeryVisuals.person(self, BakeryVisuals.CREAM, true)
 visual.rotation.y = -2.35
 tray_visual = visual.tray
func _physics_process(delta: float):
 var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
 if input_manager!=null:input=input_manager.movement(input)
 var direction := Vector3(input.x + input.y, 0, input.y - input.x).normalized()*input.length()
 velocity.x = direction.x * 4.0
 velocity.z = direction.z * 4.0
 velocity.y = -2.0
 var previous := position
 move_and_slide()
 var horizontal := Vector2(position.x - previous.x, position.z - previous.z).length()
 if horizontal > 0.001 and input.length_squared() > 0: moved.emit(horizontal)
 if direction.length_squared() > 0:
  visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 12 * delta)
 var moving := direction.length_squared() > 0
 var carrying: bool = visual.tray.visible
 visual.set_state((&"CarryWalk" if moving else &"CarryIdle") if carrying else (&"Walk" if moving else &"Idle"))
 if Input.is_action_just_pressed("interact"): interaction_requested.emit()
func show_cookies(count: int):
 visual.show_cookies(count)
func play_interaction():
 visual.interact()

func show_inventory(inventory: TrayInventory):
 visual.tray.scale.x = 1.45 if inventory.capacity >= 12 else (1.2 if inventory.capacity >= 8 else 1.0)
 visual.show_products(inventory.contents())
