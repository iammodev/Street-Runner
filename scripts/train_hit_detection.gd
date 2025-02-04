extends StaticBody3D

#TODO: Upon colliding with player, if hit to the sides, give 1 more chance
#		when hitting from the front, then die.
#		make sure to stop the players velocity.x for a short amount of time (when hit on the sides)
#		and also stop the world from generating.
#		SIDENOTE: maybe it's smarter to generate modules based on the players position, hmm?

func _on_area_front_body_entered(_body: Node3D) -> void:
	print("front")


func _on_area_right_body_entered(_body: Node3D) -> void:
	print("right")


func _on_area_left_body_entered(_body: Node3D) -> void:
	print("left")
