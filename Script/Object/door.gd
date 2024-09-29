extends StaticBody3D

var is_open = false
var open_angle = -90.0

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact"):
		if is_open:
			close_door()
		else:
			open_door()
			
func open_door():
	rotation_degrees.y = open_angle
	is_open = true

func close_door():
	rotation_degrees.y = 0
	is_open = false
