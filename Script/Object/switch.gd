extends StaticBody3D

var is_on = false
signal toggled(is_on)

func _input(event):
	if Input.is_action_just_pressed("Interact"): 
		toggle()

func toggle():
	is_on = !is_on
	emit_signal("toggled", is_on)
	update_visuals()

func update_visuals():
	if $MeshInstance3D.material_override == null:
		$MeshInstance3D.material_override = StandardMaterial3D.new()
	if is_on:
		$MeshInstance3D.material_override.albedo_color = Color.GREEN
	else:
		$MeshInstance3D.material_override.albedo_color = Color.RED
