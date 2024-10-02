extends Node3D

@onready var level_2 = preload("res://Scenes/level_2.tscn")

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		get_tree().change_scene_to_packed(level_2)
