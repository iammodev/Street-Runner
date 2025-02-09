class_name Ragdoll
extends Skeleton3D


func start_ragdoll() -> void:
	print("hello")
	physical_bones_start_simulation()

func stop_ragdoll() -> void:
	physical_bones_stop_simulation()
