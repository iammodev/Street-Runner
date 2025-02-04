class_name Level
extends Node3D

@export var base_module: PackedScene
@export var max_modules: int = 10
@export var module_spacing: float = 15.0
@export var obstacle_probability: float = 0.6
@export var total_lanes: int = 3

var rng = RandomNumberGenerator.new()
var spawned_modules = []

func _ready() -> void:
	if not base_module:
		push_error("Base module scene not assigned")
		return
		
	rng.randomize()
	initialize_track()

func initialize_track():
	for i in max_modules:
		spawn_module(i * module_spacing)

func spawn_module(x_pos: float):
	var new_module = base_module.instantiate()
	new_module.position.x = x_pos
	add_child(new_module)
	spawned_modules.append(new_module)
	
	if not configure_module(new_module):
		push_error("Failed to configure module at X: ", x_pos)

func configure_module(module: Node3D) -> bool:
	if not module:
		push_warning("Tried to configure null module")
		return false

	# Get obstacle container node
	var obstacles_node = module.get_node_or_null("Obstacles")
	if not obstacles_node:
		push_error("Module is missing 'Obstacles' node: ", module.name)
		return false

	# Generate safe lanes with at least 1 safe path
	var safe_lanes = generate_safe_lanes()
	var lane_markers = get_lane_markers(module)
	
	if lane_markers.size() != total_lanes:
		push_error("Module is missing lane markers: ", module.name)
		return false

	# Spawn obstacles
	for i in total_lanes:
		if not safe_lanes[i] and lane_markers[i]:
			spawn_obstacle(
				lane_markers[i].position,
				obstacles_node
			)
	return true

func generate_safe_lanes() -> Array[bool]:
	var safe_lanes: Array[bool]
	# Ensure at least 1 safe lane
	var random_safe_lane_amount = int(randf_range(1, total_lanes))
	while safe_lanes.count(true) < random_safe_lane_amount:
		safe_lanes = []
		for _i in total_lanes:
			safe_lanes.append(rng.randf() > obstacle_probability)
	return safe_lanes

func get_lane_markers(module: Node3D) -> Array:
	var markers = []
	for lane in ["LaneLeft", "LaneCenter", "LaneRight"]:
		var marker = module.get_node_or_null(lane)
		if marker:
			markers.append(marker)
		else:
			push_warning("Missing lane marker: Lane%s in %s" % [lane, module.name])
	return markers

func spawn_obstacle(marker_position: Vector3, parent: Node):
	if not parent or not is_instance_valid(parent):
		push_error("Invalid parent node for obstacle at position: ", position)
		return

	# Load obstacle scene safely
	var train_scene = preload("res://scenes/environment/trains/train_front02.tscn")
	if not train_scene:
		push_error("Failed to load train scene")
		return
		
	var train = train_scene.instantiate()
	if not train:
		push_error("Failed to instantiate train scene")
		return
	
	# Set position before checking duplicates
	train.position = marker_position
	
	# Unique identifier to prevent future duplicates
	train.name = "Train_%s_%s_%s" % [marker_position.x, marker_position.y, marker_position.z]
	
	# Convert node name to string explicitly
	var train_name = String(train.name)
	
	# Check for existing obstacles at this path
	if not parent.has_node(train_name):
		parent.add_child(train)
	else:
		push_warning("Duplicate obstacle detected at position: ", position, 
				   "\nExisting: ", parent.get_node(train_name).name,
				   "\nNew: ", train.name)
		train.queue_free()
