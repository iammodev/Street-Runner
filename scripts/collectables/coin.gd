extends Area3D

var _time: float = 0.0
var _is_collected: bool = false


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("collect_collectable") and !_is_collected:
		body.collect_collectable()
		
		#TODO: Play Audio
		
		$CPUParticles3D.emitting = false
		_is_collected = true
		queue_free()

func _process(delta: float) -> void:
	rotate_y(2 * delta)
	position.y += (cos(_time * 5) * 1) * delta
	
	_time += delta
