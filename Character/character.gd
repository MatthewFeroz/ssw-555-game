extends CharacterBody2D


@export var rotation_speed = PI # radians/second
@export var acceleration = 200 # pixels/second/second
@export var max_velocity = 250 # pixels/second
@export var damping = 3 # frames/second
var screen_size : Vector2
var player_size : Vector2
var min_player_pos : Vector2
var max_player_pos : Vector2

func _ready():
	# prevent the character from going offscreen
	print("Initial Position: (" + str(position.x) + ", " + str(position.y) + ")")
	screen_size = get_viewport_rect().size
	player_size = $CollisionShape.shape.get_rect().size
	min_player_pos = Vector2.ZERO + player_size / 2
	max_player_pos = screen_size - player_size / 2
	position = position.clamp(min_player_pos, max_player_pos)
	print("New Position: (" + str(position.x) + ", " + str(position.y) + ")")

# movement code taken from https://youtu.be/FmIo8iBV1W8
# TODO: decouple input into its own function; add functionality to control with mouse
func _physics_process(delta: float) -> void:
	# determine the input vector
	var input_vector = Vector2(0, 1 if Input.is_action_pressed("ui_up") else 0)
	
	# prevent the character from going offscreen
	position = position.clamp(min_player_pos, max_player_pos)

	# calculate the character's velocity (and limit it to max velocity)
	velocity += input_vector.rotated(rotation) * acceleration
	velocity = velocity.limit_length(max_velocity)
	
	# rotate the character based on the input
	if Input.is_action_pressed("ui_left"):
		rotate(-rotation_speed * delta)
	if Input.is_action_pressed("ui_right"):
		rotate(rotation_speed * delta)
	
	# if the user isn't moving forward, then let the velocity fall back to 0
	if input_vector.y == 0:
		velocity = velocity.move_toward(Vector2.ZERO, damping)
		
	move_and_slide()
