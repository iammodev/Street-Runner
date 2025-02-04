extends Node

@export var obstacle_scenes: Dictionary = {
	"train": preload("res://scenes/environment/trains/train_front02.tscn"),
	"barrier": preload("res://scenes/characters/characters_shaun.tscn")
}

func setup_obstacles(module_data: ModuleData) -> void:
	for obstacle_pos in module_data.obstacle_positions:
		var obstacle_type = "train" if randf() > 0.5 else "barrier"
		var obstacle = obstacle_scenes[obstacle_type].instantiate()
		obstacle.position = obstacle_pos
		add_child(obstacle)
