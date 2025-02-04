# module_loader.gd
extends Node3D

@export var move_speed: float = 15.0
@onready var level: Level = get_parent()

func _process(delta: float) -> void:
	# Move all modules relative to the level
	for module in level.spawned_modules:
		if is_instance_valid(module):
			module.position.x -= move_speed * delta
	
	# Check first module for despawning
	if level.spawned_modules.size() > 0:
		var first_module = level.spawned_modules[0]
		if is_instance_valid(first_module) and first_module.position.x < -10:
			recycle_module(first_module)

func recycle_module(old_module: Node3D):
	# Remove from tracking
	level.spawned_modules.erase(old_module)
	old_module.queue_free()
	
	# Spawn new module at the end
	var last_module = level.spawned_modules.back()
	var new_x = last_module.position.x + level.module_spacing
	level.spawn_module(new_x)
