extends Node3D

@export var modules: Array[PackedScene] = []
var module_amount: int = 10
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var offset: int = 5

func _ready() -> void:
	for i in module_amount:
		spawnModules(i * offset)

func spawnModules(amount) -> void:
	rng.randomize()
	var num = rng.randi_range(0, modules.size() -1)
	var instance = modules[num].instantiate()
	instance.position.x = amount
	add_child(instance)
