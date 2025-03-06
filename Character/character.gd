extends Area2D

# basic movement code taken from https://docs.godotengine.org/en/stable/getting_started/step_by_step/scripting_player_input.html
# code taken from https://gamemechanicexplorer.com/#thrust-1

@export var rotation_speed = PI # radians/second
@export var acceleration = 200 # pixels/second/second
@export var max_velocity = 250 # pixels/second
var screen_size : Vector2
var player_size : Vector2

func _ready():
	print("Initial Position: (" + str(position.x) + ", " + str(position.y) + ")")
	screen_size = get_viewport_rect().size
	player_size = $CollisionShape.shape.get_rect().size
	var min_position: Vector2 = Vector2.ZERO + player_size / 2
	var max_position: Vector2 = screen_size - player_size / 2
	position = position.clamp(min_position, max_position)
	print("New Position: (" + str(position.x) + ", " + str(position.y) + ")")

func _process(delta):
	# keep the ship on screen
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
	var direction = 0
	if Input.is_action_pressed("ui_left"):
		direction = -1
	if Input.is_action_pressed("ui_right"):
		direction = 1
	
	rotation += rotation_speed * direction * delta
	
	# calculate the velocity
	var velocity : Vector2 = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		# TODO: ensure that the spaceship actually accelerates, for now this uses the
		velocity = Vector2.UP.rotated(rotation) * acceleration
		
		# TODO: prevent the spaceship from exceeding the max speed
	
	# move the character
	position += velocity * delta
