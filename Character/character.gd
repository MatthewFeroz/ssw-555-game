extends CharacterBody2D

# inspiration for movement code comes from https://gamemechanicexplorer.com/#thrust-1

# inspector variables
@export var rotation_speed = PI # radians/second
@export var acceleration = 200 # pixels/second/second
@export var max_velocity = 250 # pixels/second
@export var damping = 3 # frames/second
@export var mouse_mode = true # whether the mouse or not is the main input

# mouse-only variables
var target = position # where the player clicked on the screen
var total_distance = position.distance_to(target) # distance between starting position and target
"""
by default, the character is pointing down (look at the Character node in the scene).
when Godot applies rotations, it assumes that the character is pointing towards the right.
this is fine when it's keyboard input, but it's a problem for mouse input.
everytime we switch inputs, we need to correct the way the character is facing.
"""
var character_angle : float = PI / 2 # radians

# keyboard-only variables
var input_vector : Vector2

# global variables
var SCREEN_SIZE : Vector2
var PLAYER_SIZE : Vector2
var MIN_PLAYER_POS : Vector2
var MAX_PLAYER_POS : Vector2

func _ready():
	# prevent the character from being spawned offscreen
	print("Initial Position: (" + str(position.x) + ", " + str(position.y) + ")")
	SCREEN_SIZE = get_viewport_rect().size
	PLAYER_SIZE = $CollisionShape.shape.get_rect().size
	MIN_PLAYER_POS = Vector2.ZERO + PLAYER_SIZE / 2
	MAX_PLAYER_POS = SCREEN_SIZE - PLAYER_SIZE / 2
	position = position.clamp(MIN_PLAYER_POS, MAX_PLAYER_POS)
	print("New Position: (" + str(position.x) + ", " + str(position.y) + ")")

# function to get keyboard input
func get_input(delta):
	input_vector = Vector2(0, 1 if Input.is_action_pressed("move_forward") else 0)
	
	# rotate the character based on the input
	if Input.is_action_pressed("rotate_left"):
		rotate(-rotation_speed * delta)
	if Input.is_action_pressed("rotate_right"):
		rotate(rotation_speed * delta)

# function to get (mouse / keyboard) input
# code for switching between mouse and keyboard from https://www.reddit.com/r/godot/comments/itr0da/comment/g5kbl2r/
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		mouse_mode = false
	elif event is InputEventMouseButton and event.is_action_pressed("move_forward"):
		mouse_mode = true
		target = get_global_mouse_position()
		total_distance = position.distance_to(target)
	
	print("Mouse Mode: %s" % str(mouse_mode))
	print(event.as_text())

# movement code for character in keyboard mode taken from https://youtu.be/FmIo8iBV1W8
func _physics_process(delta: float) -> void:
	# calculate the character's velocity (and limit it to max velocity)
	if not mouse_mode:
		# determine the input vector
		get_input(delta)
		velocity += input_vector.rotated(rotation) * acceleration
		# if the user isn't moving forward, then let the velocity fall back to 0
		if input_vector.y == 0:
			velocity = velocity.move_toward(Vector2.ZERO, damping)
	else:
		# using interpolation because the player will move at a non-constant speed
		velocity = position.direction_to(target) * max_velocity
		# needs to be rotated 90 degrees because front of character is pointing down
		rotation = get_global_mouse_position().angle_to_point(position) + character_angle
		
		# if the user is approaching target, then let the velocity fall back to 0
		# TODO: figure out how to dampen velocity when in mouse mode
		#if position.distance_to(target) <= 0.25 * total_distance:
			#velocity = velocity.move_toward(Vector2.ZERO, damping)
	velocity = velocity.limit_length(max_velocity)
	
	# rotate the character based on the keyboard input
	if not mouse_mode:
		if Input.is_action_pressed("rotate_left"):
			rotate(-rotation_speed * delta)
		if Input.is_action_pressed("rotate_right"):
			rotate(rotation_speed * delta)
	
	# prevent the character from going offscreen
	position = position.clamp(MIN_PLAYER_POS, MAX_PLAYER_POS)
	print("Current Velocity: %.2f px/s" % velocity.length())
	print("Current Rotation: %d°" % rad_to_deg(rotation))
	
	# if in mouse mode, only move when more than 10 units away from target
	# if not, then just move anyway
	if not mouse_mode or (mouse_mode and position.distance_to(target) > 10):
		move_and_slide()
