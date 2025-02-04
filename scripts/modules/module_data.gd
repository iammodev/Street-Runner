class_name ModuleData
extends Resource

@export var scene: PackedScene
@export var safe_lanes: Array[bool] = [true, true, true] # [left, center, right]
@export var obstacle_positions: Array[Vector3] = []
