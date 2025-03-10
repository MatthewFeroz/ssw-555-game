extends Node

var player_scene = preload("res://scenes/character.tscn")

func _ready():
	print("Running unit tests...")
	test_player_initial_position()
	test_player_movement()
	print("All tests passed!")

func assert_equal(actual, expected, message=""):
	if actual != expected:
		push_error("Test Failed: %s" % message)
		assert(false)

func test_player_initial_position():
	var player = player_scene.instantiate()
	add_child(player)
	var viewport_size = get_viewport().get_visible_rect().size
	
	var pos = player.position
	assert(pos.x >= 0 and pos.x <= viewport_size.x)
	assert(pos.y >= 0 and pos.y <= viewport_size.y)
	print("test_player_initial_position passed")

func test_player_movement():
	var player = player_scene.instantiate()
	add_child(player)

	player.velocity = Vector2(0, 0)
	player.rotation = 0
	player.acceleration = 100
	player.rotation_speed = PI / 2
	player.mouse_mode = false

	# Simulate pressing move_forward
	Input.action_press("move_forward")
	player.get_input(1.0)
	Input.action_release("move_forward")
	
	assert(player.input_vector.y == 1)

	# Simulate rotation left
	var initial_rotation = player.rotation
	Input.action_press("rotate_left")
	player._physics_process(1.0)
	Input.action_release("rotate_left")
	
w	assert(player.rotation < 0)

	print("test_player_movement passed")
