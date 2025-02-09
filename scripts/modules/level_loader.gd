# This Level class is responsible for generating the level layout by spawning 
# modules (sections) and placing obstacles (like trains) within these modules.
# It manages lane safety (i.e. ensuring at least one lane is safe per module) 
# and reserves lanes for moving obstacles over several modules.

class_name Level
extends Node3D

# ------------------------------------------------------------
# Exported Variables (Editable in the Inspector)
# ------------------------------------------------------------

# The base module scene used as a template for each level segment.
@export var base_module: PackedScene

# A node responsible for loading modules; its properties (e.g., move_speed) 
# are used to calculate obstacle speeds.
@export var module_loader: Node3D

# Level Layout Settings
@export var max_modules: int = 10           # Total number of modules (sections) to spawn.
@export var module_spacing: float = 15.0      # Distance between consecutive modules along the X-axis.

# Obstacle Settings
@export var obstacle_probability: float = 0.6     # Likelihood (inversely) that an obstacle is safe.
@export var moving_obstacle_chance: float = 0.3     # Chance that an obstacle will be set as moving (if allowed).
@export var obstacle_speed_offset: float = 5.0      # Additional speed offset for moving obstacles relative to module_loader.

# Lane Settings
@export var total_lanes: int = 3           # Total number of lanes available per module.
@export var safe_lane_count: int = 1       # Number of modules for which a reserved lane remains safe (no obstacles).

# ------------------------------------------------------------
# Internal Variables
# ------------------------------------------------------------

var rng = RandomNumberGenerator.new()     # Random number generator instance for procedural decisions.
var spawned_modules: Array = []             # Keeps track of all modules spawned.
# Dictionary mapping lane indices to their reservation counts; a reserved lane remains safe for a set number of modules.
var reserved_lanes: Dictionary = {}
var pending_reserved_lanes: Dictionary = {}

# ------------------------------------------------------------
# Lifecycle Callback Functions
# ------------------------------------------------------------

func _ready() -> void:
	"""
	Called when the node enters the scene tree.
	Verifies necessary resources, randomizes the RNG, and initializes the level track.
	"""
	if not base_module:
		push_error("Base module scene not assigned")
		return
		
	rng.randomize()         # Seed the RNG to ensure unpredictable behavior.
	initialize_track()      # Begin generating the level modules.

# ------------------------------------------------------------
# Level Initialization and Module Spawning
# ------------------------------------------------------------

func initialize_track():
	"""
	Generates the level by spawning a series of modules spaced along the X-axis.
	"""
	for i in range(max_modules):
		spawn_module(i * module_spacing)

func spawn_module(x_pos: float):
	"""
	Instantiates and positions a single level module at the specified X-axis location.
	Also configures the module (e.g., obstacle placement) and updates lane reservations.
	
	@param x_pos: The X-axis coordinate for the new module.
	"""
	
	# from moving obstacles spawned in the previous module.
	for lane in pending_reserved_lanes.keys():
		reserved_lanes[lane] = pending_reserved_lanes[lane]
	pending_reserved_lanes.clear()
	
	# Refresh lane reservations before configuring the module.
	update_reservations()
	
	var new_module = base_module.instantiate()
	new_module.position.x = x_pos
	add_child(new_module)
	spawned_modules.append(new_module)
	
	# Configure obstacles and lane safety for this module.
	if not configure_module(new_module, spawned_modules.size() - 1):
		push_error("Failed to configure module at X: " + str(x_pos))

# ------------------------------------------------------------
# Module Configuration (Obstacles & Lane Safety)
# ------------------------------------------------------------

func configure_module(module: Node3D, module_index: int) -> bool:
	"""
	Sets up a module by determining safe lanes and spawning obstacles accordingly.
	Ensures each module has the correct lane markers and obstacle container.
	
	@param module: The level module node to be configured.
	@param module_index: Index of the module (used to enable moving obstacles after a few modules).
	@return: True if the module is configured successfully, False otherwise.
	"""
	if not module:
		push_warning("Tried to configure null module")
		return false

	# Retrieve the obstacles container within the module.
	var obstacles_node = module.get_node_or_null("Obstacles")
	if not obstacles_node:
		push_error("Module is missing 'Obstacles' node: " + module.name)
		return false

	# Determine which lanes should be safe (i.e., free of obstacles) for this module.
	var safe_lanes = generate_safe_lanes()
	
	# Get lane marker nodes that define where obstacles will be placed.
	var lane_markers = get_lane_markers(module)
	if lane_markers.size() != total_lanes:
		push_error("Module is missing lane markers: " + module.name)
		return false

	# Enforce any lane reservations from previous modules by marking those lanes as safe.
	for lane in reserved_lanes:
		if lane < total_lanes:
			safe_lanes[lane] = true

	# Loop through each lane; if the lane is not safe, spawn an obstacle there.
	for i in total_lanes:
		if not safe_lanes[i] and lane_markers[i]:
			# Allow moving obstacles only after the first couple of modules.
			var allow_moving = module_index >= 2
			var _is_moving: bool = allow_moving and rng.randf() < moving_obstacle_chance
			spawn_obstacle(lane_markers[i].position, obstacles_node, _is_moving, i)
	return true

# ------------------------------------------------------------
# Safe Lane Generation
# ------------------------------------------------------------

## Determine which lanes should be safe (i.e., free of obstacles) for this module.
func generate_safe_lanes() -> Array[bool]:
	"""
	Creates an array representing safe lanes (true means safe).
	Considers reserved lanes and ensures that at least one lane is safe.
	
	@return: Array of booleans indicating the safety of each lane.
	"""
	var safe_lanes: Array[bool] = []
	safe_lanes.resize(total_lanes)
	
	var has_safe: bool = false
	var attempts: int = 0
	# Try up to 10 times to generate at least one safe lane.
	while attempts < 10 and not has_safe:
		attempts += 1
		# For each lane, force safety if reserved; otherwise, use random chance.
		for i in total_lanes:
			if reserved_lanes.has(i):
				print("Generated random safe lanes, considering reservations")
				safe_lanes[i] = true
			else:
				safe_lanes[i] = rng.randf() > obstacle_probability
		# Check that there is at least one safe lane.
		has_safe = safe_lanes.count(true) >= 1
	
	# If no safe lane is found, force one in a non-reserved lane.
	if not has_safe:
		print("Force safe lane, none found")
		var non_reserved: Array = []
		for i in total_lanes:
			if not reserved_lanes.has(i):
				non_reserved.append(i)
		if non_reserved.size() > 0:
			var idx = rng.randi() % non_reserved.size()
			print("idx", idx)
			safe_lanes[non_reserved[idx]] = true
		else:
			# If all lanes are reserved (very unlikely), consider them all safe.
			print("All lanes reserved, they're all safe")
	return safe_lanes

# ------------------------------------------------------------
# Lane Marker Retrieval & Obstacle Spawning
# ------------------------------------------------------------

func get_lane_markers(module: Node3D) -> Array:
	"""
	Collects lane marker nodes from a module. Lane markers indicate the positions
	where obstacles (like trains) should be placed.
	
	@param module: The module node to scan for lane markers.
	@return: Array of lane marker nodes. Expected order: LaneLeft, LaneCenter, LaneRight.
	"""
	var markers = []
	for lane in ["LaneLeft", "LaneCenter", "LaneRight"]:
		var marker = module.get_node_or_null(lane)
		if marker:
			markers.append(marker)
		else:
			push_warning("Missing lane marker: " + str(lane) + " in " + module.name)
	return markers

func spawn_obstacle(marker_position: Vector3, parent: Node, _is_moving: bool = false, lane_index: int = -1):
	"""
	Spawns an obstacle (e.g., a train) at the given marker position.
	If the obstacle is moving, reserves the lane for subsequent modules.
	
	@param marker_position: The position where the obstacle will appear.
	@param parent: The node that will act as the container for the obstacle.
	@param _is_moving: Indicates if the spawned obstacle should have moving behavior.
	@param lane_index: The index of the lane where the obstacle is placed.
	"""
	# Validate the parent node before proceeding.
	if not parent or not is_instance_valid(parent):
		push_error("Invalid parent node for obstacle at position: " + str(marker_position))
		return

	# Preload the obstacle scene (in this case, a train).
	var train_scene = preload("res://scenes/environment/trains/train_front02.tscn")
	if not train_scene:
		push_error("Failed to load train scene")
		return
	
	# Instantiate the train obstacle.
	var train = train_scene.instantiate()
	if not train:
		push_error("Failed to instantiate train scene")
		return
	
	# If the obstacle should be moving, reserve the lane and set the moving speed.
	if _is_moving and module_loader and lane_index != -1:
		pending_reserved_lanes[lane_index] = safe_lane_count
		
		# Reserve the lane so that subsequent modules treat it as safe for a number of modules.
		#reserved_lanes[lane_index] = safe_lane_count
		var required_speed = module_loader.move_speed + obstacle_speed_offset
		if train.has_method("set_moving"):
			train.set_moving(required_speed)
		else:
			push_warning("Train scene missing set_moving method")
	
	# Place the train at the specified marker position.
	train.position = marker_position
	
	# Create a unique name for the obstacle based on its position to prevent duplicates.
	train.name = "Train_%s_%s_%s" % [marker_position.x, marker_position.y, marker_position.z]
	var train_name = String(train.name)
	
	# Add the train to the parent if an obstacle with the same name doesn't already exist.
	if not parent.has_node(train_name):
		parent.add_child(train)
	else:
		push_warning("Duplicate obstacle detected at position: " + str(marker_position) +
			"\nExisting: " + parent.get_node(train_name).name +
			"\nNew: " + train.name)
		train.queue_free()

# ------------------------------------------------------------
# Reserved Lane Management
# ------------------------------------------------------------

func update_reservations():
	"""
	Decrements the reservation countdown for each reserved lane.
	Once a reservation reaches zero (or less), it is removed, allowing obstacles
	to be spawned in that lane in future modules.
	"""
	for lane in reserved_lanes.keys():
		reserved_lanes[lane] -= 1
		if reserved_lanes[lane] <= 0:
			reserved_lanes.erase(lane)
