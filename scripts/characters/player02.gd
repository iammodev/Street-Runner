extends CharacterBody3D

## Movement Settings
enum MovementDirection { LEFT = -1, RIGHT = 1 }
const LANE_POSITIONS: Array = [Vector3(0, 1, -3), Vector3(0, 1, 0), Vector3(0, 1, 3)]
@export var SWIPE_THRESHOLD: int = 100
@export var MOVE_SPEED: float = 3.0
@export var SWIPE_SPEED: float = 8.0
@export var JUMP_FORCE: float = 4.5
@export var GRAVITY: float = 9.8
@export var FAST_FALL_GRAVITY_MULTIPLIER: float = 2.5  # Multiplier for faster falling

var _current_lane: int = 1
var _target_z: float = 0.0
var _original_z: float = 0.0  # Store the original lane position when moving
var _swipe_start: Vector2 = Vector2.ZERO
var _swipe_end: Vector2 = Vector2.ZERO # Current Swipe
var _is_swiping: bool = false
var _is_fast_falling: bool = false
var _is_interrupted: bool = false  # Track if the player is interrupted during lane movement

func _ready() -> void:
	position = LANE_POSITIONS[_current_lane]
	_target_z = position.z
	_original_z = position.z  # Initialize original position

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		if _is_fast_falling:
			velocity.y -= GRAVITY * FAST_FALL_GRAVITY_MULTIPLIER * delta  # Apply faster gravity
		else:
			velocity.y -= GRAVITY * delta
	else:
		_is_fast_falling = false  # Reset fast fall when landing

	# Move forward
	velocity.x = MOVE_SPEED * delta
	
	# Horizontal lane movement
	var current_z = position.z
	var delta_z = _target_z - current_z
	
	if abs(delta_z) > 0.2:
		velocity.z = sign(delta_z) * SWIPE_SPEED
	else:
		velocity.z = 0
		position.z = _target_z  # Snap to target position
		if _is_interrupted:
			_is_interrupted = false
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	# Handle swipe events
	if event.is_action_pressed("swipe"):
		_start_swipe(event)
	elif event.is_action_released("swipe"):
		_end_swipe(event)
	elif event.is_action_pressed("test"):
		interrupt_movement()

	# Handle key press input
	if event.is_action_pressed("move_left"):
		_move_left()
	elif event.is_action_pressed("move_right"):
		_move_right()
	elif event.is_action_pressed("move_up"):
		_move_up()
	elif event.is_action_pressed("move_down"):
		_move_down()  # Handle fast fall

func _start_swipe(event: InputEvent) -> void:
	_is_swiping = true
	_swipe_start = event.position

func _end_swipe(event: InputEvent) -> void:
	if !_is_swiping: return
	_is_swiping = false
	
	_swipe_end = event.position
	var swipe_vector = _swipe_end - _swipe_start
	if swipe_vector.length() < SWIPE_THRESHOLD: return
	
	# Horizontal swipe
	if abs(swipe_vector.x) > abs(swipe_vector.y):
		var direction = sign(swipe_vector.x)
		_handle_swipe_direction(direction)
	# Vertical swipe (up)
	elif swipe_vector.y < -SWIPE_THRESHOLD:
		_move_up()
	# Vertical swipe (down)
	elif swipe_vector.y > SWIPE_THRESHOLD:
		_move_down()

func _handle_swipe_direction(direction: int) -> void:
	match direction:
		MovementDirection.RIGHT:
			_move_right()
		MovementDirection.LEFT:
			_move_left()

func _move_left() -> void:
	set_current_lane(_current_lane - 1)

func _move_right() -> void:
	set_current_lane(_current_lane + 1)

func _move_up() -> void:
	if is_on_floor():
		velocity.y = JUMP_FORCE

func _move_down() -> void:
	if not is_on_floor():  # Only allow fast fall if in the air
		_is_fast_falling = true

func set_current_lane(value: int) -> void:
	var new_lane = clamp(value, 0, LANE_POSITIONS.size() - 1)
	if new_lane != _current_lane:
		_original_z = position.z  # Store the original position before moving
		_current_lane = new_lane
		_target_z = LANE_POSITIONS[_current_lane].z

## Call this function when the player is interrupted (e.g., hits a train)
func interrupt_movement() -> void:
	if not _is_interrupted:
		_is_interrupted = true
		_target_z = _original_z  # Set the target back to the original lane
		_current_lane = LANE_POSITIONS.find(Vector3(0, 1, _original_z))  # Update current lane
