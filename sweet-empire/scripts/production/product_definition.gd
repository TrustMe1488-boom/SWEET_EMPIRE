class_name ProductDefinition
extends Resource
@export var id: StringName
@export var display_name: String
@export var sale_price: int
@export var base_time: float
@export var icon_kind: String
@export var station_id: StringName
@export var station_name: String
@export var purchase_cost: int
@export var hire_cost: int
@export var upgrade_factor: int
@export var zone: int = 1
@export var world_position: Vector3
@export var visual_scene: String
func production_time(level: int) -> float:
 return base_time * pow(0.85, clampi(level, 1, 5) - 1)
func upgrade_cost(level: int) -> int:
 return 50 * level * upgrade_factor if level >= 1 and level < 5 else 0
