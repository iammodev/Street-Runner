extends Area3D

## Movement Settings
enum MovementDirection { LEFT = -1, RIGHT = 1 }
const LANE_POSITIONS: Array = [Vector3(0, 1, -3), Vector3(0, 1, 0), Vector3(0, 1, 3)]
## How many pixels to swipe for the swipe detection to register as a swipe
@export var SWIPE_THRESHOLD: int = 100

var _target_position: Vector3 = LANE_POSITIONS[_current_lane]
## Smooth Movement duration
@export var TWEEN_MOVE_DURATION: float = 0.3

var _current_lane: int = 1:
	set(value):
		var new_lane = clamp(value, 0, LANE_POSITIONS.size() - 1)
		if new_lane != _current_lane:
			_current_lane = new_lane
			_move_to_lane(LANE_POSITIONS[_current_lane])

func set_current_lane(value: int) -> void:
	var new_lane = clamp(value, 0, LANE_POSITIONS.size() - 1)
	if new_lane != _current_lane:
		_current_lane = new_lane
		_move_to_lane(LANE_POSITIONS[_current_lane])

## Input Handling
var _swipe_start: Vector2 = Vector2.ZERO
var _swipe_end: Vector2 = Vector2.ZERO
var _is_swiping: bool = false

func _ready() -> void:
	# Initialize position
	position = LANE_POSITIONS[_current_lane]

func _input(event: InputEvent) -> void:
	# Handle swipe events
	if event.is_action_pressed("swipe"):
		_start_swipe(event)
	elif event.is_action_released("swipe"):
		_end_swipe(event)

	# Handle key press input for movement (W, A, D)
	if event.is_action_pressed("move_left"):
		_move_left()
	elif event.is_action_pressed("move_right"):
		_move_right()
	elif event.is_action_pressed("move_up"):
		_move_up()

func _start_swipe(_event: InputEvent) -> void:
	_is_swiping = true
	_swipe_start = get_viewport().get_mouse_position()

func _end_swipe(_event: InputEvent) -> void:
	if !_is_swiping: return
	_is_swiping = false
	
	_swipe_end = get_viewport().get_mouse_position()
	var swipe_vector = _swipe_end - _swipe_start
	if swipe_vector.length() < SWIPE_THRESHOLD: return
	
	var direction = sign(swipe_vector.x)
	_handle_swipe_direction(direction)
	
	# Vertical swipe (upwards for jump movement)
	if swipe_vector.y < -SWIPE_THRESHOLD:
		_move_up()

func _handle_swipe_direction(direction: int) -> void:
	match direction:
		MovementDirection.RIGHT:
			_move_right()
		MovementDirection.LEFT:
			_move_left()
		_:
			return

func _move_left() -> void:
	_current_lane -= 1
	_target_position = LANE_POSITIONS[_current_lane]
	_move_to_lane(_target_position)

func _move_right() -> void:
	_current_lane += 1
	_target_position = LANE_POSITIONS[_current_lane]
	_move_to_lane(_target_position)

func _move_up() -> void:
	#TODO: Add Proper Jump with gravity, but how?
	_target_position.y += 3  # Arbitrary upward movement
	_move_to_lane(_target_position)

func _move_to_lane(target_position: Vector3) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, TWEEN_MOVE_DURATION)
