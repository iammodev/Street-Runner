extends StaticBody3D

#TODO: Upon colliding with player, if hit to the sides, give 1 more chance
#		when hitting from the front, then die.
#		make sure to stop the players velocity.x for a short amount of time (when hit on the sides)
#		and also stop the world from generating.
#		SIDENOTE: maybe it's smarter to generate modules based on the players position, hmm?

var ragdoll_instance

var _is_moving: bool = false
var _move_speed: float = 0.0

func _ready() -> void:
	ragdoll_instance = Ragdoll.new()

func _process(delta: float) -> void:
	if _is_moving:
		position.x -= _move_speed * delta

func set_moving(speed: float) -> void:
	_is_moving = true
	_move_speed = speed

func _on_area_front_body_entered(_body: Node3D) -> void:
	ragdoll_instance.start_ragdoll()
	print("front")


func _on_area_right_body_entered(body: Node3D) -> void:
	if body.has_method("interrupt_movement"):
		body.interrupt_movement()
	print("right")


func _on_area_left_body_entered(body: Node3D) -> void:
	if body.has_method("interrupt_movement"):
		body.interrupt_movement()
	print("left")
