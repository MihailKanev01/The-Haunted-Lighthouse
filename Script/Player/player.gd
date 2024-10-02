extends CharacterBody3D

const WALKING_SPEED: float = 5.0
const SPRINTING_SPEED: float = 6.0
const CROUCHING_SPEED: float = 3.5
const CRAWLING_SPEED: float = 2.5
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 12.5
const CAMERA_SENSITIVITY: float = 0.25
const CAMERA_ACCELERATION: float = 5.0

# Footstep intervals (in seconds)
const WALKING_STEP_INTERVAL: float = 0.5
const SPRINTING_STEP_INTERVAL: float = 0.3
const CROUCHING_STEP_INTERVAL: float = 0.7
const CRAWLING_STEP_INTERVAL: float = 0.9

var current_speed: float = WALKING_SPEED
var head_y_axis: float = 0.0
var camera_x_axis: float = 0.0
var time_since_last_step: float = 0.0 # Timer for footsteps
var step_interval: float = WALKING_STEP_INTERVAL # Default walking interval

var is_crouching = false
var is_crawling = false
var true_speed: float = WALKING_SPEED

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera
@onready var hand: Node3D = $Hand
@onready var standing_flashlight: SpotLight3D = $Hand/StandingFlashlight
@onready var crouching_flashlight: SpotLight3D = $Hand/CrouchingFlashlight
@onready var crawling_flashlight: SpotLight3D = $Hand/CrawlingFlashlight
@onready var footstep: AudioStreamPlayer3D = $Footstep
@onready var animation_player: AnimationPlayer = $AnimationPlayer # Add a reference to AnimationPlayer

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		head_y_axis += event.relative.x * CAMERA_SENSITIVITY
		camera_x_axis -= event.relative.y * CAMERA_SENSITIVITY
		
		camera_x_axis = clamp(camera_x_axis, -90, 90)

func _process(delta: float) -> void:
	head.rotation.y = lerp(head.rotation.y, -deg_to_rad(head_y_axis), CAMERA_ACCELERATION * delta)
	camera.rotation.x = lerp(camera.rotation.x, deg_to_rad(camera_x_axis), CAMERA_ACCELERATION * delta)
	
	# Flashlight control with head movement
	hand.rotation.y = -deg_to_rad(head_y_axis)
	update_flashlight_direction()

	# Handle jumping and gravity
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	
	# Handle crouching, crawling, and sprinting states
	if Input.is_action_just_pressed("crouch"):
		if not is_crouching:
			movement_state_change("crouch")
			true_speed = CROUCHING_SPEED
			step_interval = CROUCHING_STEP_INTERVAL
		else:
			movement_state_change("uncrouch")
			true_speed = WALKING_SPEED
			step_interval = WALKING_STEP_INTERVAL

	elif Input.is_action_just_pressed("crawl"):
		if not is_crawling:
			movement_state_change("crawl")
			true_speed = CRAWLING_SPEED
			step_interval = CRAWLING_STEP_INTERVAL
		else:
			movement_state_change("uncrawl")
			true_speed = WALKING_SPEED
			step_interval = WALKING_STEP_INTERVAL

	elif Input.is_action_pressed("sprint") and !is_crouching and !is_crawling:
		current_speed = SPRINTING_SPEED
		step_interval = SPRINTING_STEP_INTERVAL # Shorter step interval for sprinting
	else:
		current_speed = WALKING_SPEED
		step_interval = WALKING_STEP_INTERVAL # Normal interval for walking
	
	# Handle player movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Play footstep sound when moving and on floor
	if is_on_floor() and direction.length() > 0:
		time_since_last_step += delta
		if time_since_last_step >= step_interval:
			footstep.play()  # Play the footstep sound
			time_since_last_step = 0.0  # Reset the timer
	else:
		time_since_last_step = 0.0  # Reset the timer when not moving
	
	# Move the player based on the input direction and speed
	if is_on_floor():
		if direction:
			velocity.x = direction.x * true_speed
			velocity.z = direction.z * true_speed
		else:
			velocity.x = move_toward(velocity.x, 0, true_speed)
			velocity.z = move_toward(velocity.z, 0, true_speed)
	
	# Remove the argument here for Godot 4.x compatibility
	move_and_slide()

# Handle crouching, crawling, standing animations and collision shapes
func movement_state_change(change_type: String) -> void:
	match change_type:
		"crouch":
			if is_crawling:
				$AnimationPlayer.play_backwards("CrouchToCrawl")
			else:
				$AnimationPlayer.play("StandingToCrouch")
			is_crouching = true
			change_collision_shape_to("crouching")
			is_crawling = false
			enable_flashlight("crouching")
			
		"uncrouch":
			$AnimationPlayer.play_backwards("StandingToCrouch")
			is_crouching = false
			is_crawling = false
			change_collision_shape_to("standing")
			enable_flashlight("standing")

		"crawl":
			if is_crouching:
				$AnimationPlayer.play("CrouchToCrawl")
			else:
				$AnimationPlayer.play("StandingToCrawl")
			is_crouching = false
			is_crawling = true
			change_collision_shape_to("crawling")
			enable_flashlight("crawling")

		"uncrawl":
			$AnimationPlayer.play_backwards("StandingToCrawl")
			is_crawling = false
			is_crouching = false
			change_collision_shape_to("standing")
			enable_flashlight("standing")

# Change collision shapes for standing, crouch, crawl
func change_collision_shape_to(shape: String) -> void:
	match shape:
		"crouching":
			$CrouchingCollisionShape.disabled = false
			$CrawlingCollisionShape.disabled = true
			$StandingCollisionShape.disabled = true
		"standing":
			$StandingCollisionShape.disabled = false
			$CrawlingCollisionShape.disabled = true
			$CrouchingCollisionShape.disabled = true
		"crawling":
			$CrawlingCollisionShape.disabled = false
			$StandingCollisionShape.disabled = true
			$CrouchingCollisionShape.disabled = true

# Enable the correct flashlight based on movement state and disable others
func enable_flashlight(state: String) -> void:
	match state:
		"crouching":
			crouching_flashlight.visible = true
			standing_flashlight.visible = false
			crawling_flashlight.visible = false
		"standing":
			standing_flashlight.visible = true
			crouching_flashlight.visible = false
			crawling_flashlight.visible = false
		"crawling":
			crawling_flashlight.visible = true
			standing_flashlight.visible = false
			crouching_flashlight.visible = false

# Update flashlight direction with the player's head movement
func update_flashlight_direction() -> void:
	crouching_flashlight.rotation.x = deg_to_rad(camera_x_axis)
	standing_flashlight.rotation.x = deg_to_rad(camera_x_axis)
	crawling_flashlight.rotation.x = deg_to_rad(camera_x_axis)
