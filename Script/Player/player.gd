extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var jump_sound = $JumpSound
var was_in_air = false
@onready var landing_sound = $LandingSound
var interact_range = 3.0
var interact_ray = RayCast3D.new()

func _ready():
	add_child(interact_ray)
	interact_ray.target_position = Vector3(0, 0, interact_range)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Interact"):
		interact_ray.force_raycast_update()
		if interact_ray.is_colliding():
			var collider = interact_ray.get_collider()
			if collider.has_meta("open door"):
				collider.open_door()

	if not is_on_floor():
		velocity += get_gravity() * delta
		was_in_air = true
	elif was_in_air:
		landing_sound.play()
		was_in_air = false

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
