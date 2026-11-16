class_name CosmeticDefinition
extends Resource
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export_enum("MIA_OUTFIT","INTERIOR_THEME","DESSERT_STYLE") var category: String = "MIA_OUTFIT"
@export_range(0,10000) var price: int = 0
@export var is_free: bool = false
@export var style: CosmeticStyle
@export var visual_scene: PackedScene
@export var preview_camera_size: float = 3.2
@export var preview_rotation_speed: float = 0.22
