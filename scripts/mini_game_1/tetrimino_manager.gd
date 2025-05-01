@tool
class_name TetriminoManager
extends Node

# signals
signal probabilities_changed(new_probs: Array)

# constants for tetrimino shape data
const TETRIMINO_SHAPES_PATH = "res://resources/shapes/tetrimino_shapes.tres"
const TETRIMINO_DATA = preload(TETRIMINO_SHAPES_PATH) # tetrimino_shape: key, shape_data: value
const VALID_SHAPES = ["O", "I", "T", "L", "J", "S", "Z"]

# constants for block scene
const BLOCK_SCENE_PATH = "res://scenes/mini_game_1/block.tscn"
const BLOCK_SCENE = preload(BLOCK_SCENE_PATH)

# inspector variables
@export_enum("O", "I", "T", "L", "J", "S", "Z") var tetrimino_shape: String = "O":
	set(new_shape):
		t_shape = new_shape
		tetrimino_shape = new_shape
		if Engine.is_editor_hint():
			call_deferred("spawn_tetrimino")
			#add_child(tetrimino)

@export var tetrimino_block_size = 128.0:
	set(new_size):
		block_size = new_size
		tetrimino_block_size = new_size
		if Engine.is_editor_hint():
			call_deferred("spawn_tetrimino")
			#add_child(tetrimino)

@export_enum("0°", "90°", "180°", "270°") var rotation_angle: int = 0:
	set(new_angle):
		rotation_index = new_angle
		rotation_angle = new_angle
		if Engine.is_editor_hint():
			call_deferred("spawn_tetrimino")
			#add_child(tetrimino)

# member variables
var tetrimino: Tetrimino
var t_shape: String = "O"
var block_size: float = 128.0 # the original texture size is 128x128
var rotation_index: int = 0
var in_superposition: bool = false
var probabilities: Array = []

# built-in functions
func _ready() -> void:
	if not Engine.is_editor_hint():
		tetrimino = spawn_tetrimino()

# custom functions

# getter functions
func get_tetrimino() -> Tetrimino:
	return tetrimino
	
static func get_valid_shapes() -> Array:
	return VALID_SHAPES

#func get_tetrimino_shape_name() -> String:
	#return tetrimino_shape
#
#func get_block_size() -> float:
	#return BLOCK_SIZE
#
#func get_rotation_angle() -> int:
	#return rotation_index * 90

# creating and freeing tetriminos
func spawn_tetrimino(
	shape_name: String = t_shape,
	block_size: float = block_size,
	rotation_index: int = rotation_index
) -> Tetrimino:
	# Get valid rotations for this shape
	var valid_rotations = Tetrimino.get_valid_rotations(shape_name)
	# Ensure rotation index is valid for this shape
	rotation_index = rotation_index % valid_rotations.size()

	# Check for existing tetrimino first
	if has_node("Tetrimino"):
		tetrimino = get_node("Tetrimino")
		tetrimino.clear_blocks()
	else:
		tetrimino = Tetrimino.new()
		tetrimino.name = "Tetrimino"
		add_child(tetrimino)
		
		if tetrimino.get_child_count() == 0:
			var blocks = Node2D.new()
			blocks.name = "Blocks"
			tetrimino.add_child(blocks)

	# Setup tetrimino properties
	tetrimino._shape = shape_name
	tetrimino._block_size = block_size
	tetrimino._rotation_index = rotation_index
	tetrimino._valid_rotations = valid_rotations
	tetrimino.tetrimino_manager = self

	# Create blocks
	var blocks = tetrimino.get_blocks()
	var shape_data = TETRIMINO_DATA["shapes"][shape_name]
	var coords = shape_data["coords"][rotation_index]
	var color = shape_data["color"]

	# Calculate center offset for auto-centering
	var min_x = INF
	var max_x = -INF
	var min_y = INF
	var max_y = -INF
	
	for coord in coords:
		min_x = min(min_x, coord.x)
		max_x = max(max_x, coord.x)
		min_y = min(min_y, coord.y)
		max_y = max(max_y, coord.y)
	
	var center_offset = Vector2(
		(min_x + max_x) * block_size * 0.5,
		(min_y + max_y) * block_size * 0.5
	)

	var block_num = 1
	for coord in coords:
		var block = BLOCK_SCENE.instantiate()
		block.name = "Block %d" % block_num
		block.set_block_color(color)
		block.resize_block(block_size)
		blocks.add_child(block)
		
		# Position block relative to center
		block.position = (coord * block_size) - center_offset
		block_num += 1

	# Handle UI preview specific setup
	if is_child_of_preview():
		tetrimino.can_fall = false
		
	if not tetrimino.probs_changed.is_connected(_on_probabilities_changed):
		tetrimino.probs_changed.connect(_on_probabilities_changed)

	return tetrimino

func free_tetrimino(
	tetrimino: Tetrimino
) -> void:
	tetrimino.clear_blocks() # get rid of existing blocks first
	tetrimino.name = "DeletedTetrimino"
	tetrimino.queue_free()
	
	# reset all of the member variables to their defaults
	t_shape = "O"
	block_size = 128.0
	rotation_index = 0

"""
In the tetrimino_slot scene, TetriminoManager will be a child of 
TetriminoPreview. This function simply checks if it is a child of that node.
"""
func is_child_of_preview() -> bool:
	var parent = get_parent()
	return parent.name == "TetriminoPreview"

func lock() -> void:
	tetrimino._lock()

func collapse() -> void:
	tetrimino._collapse()

func toggle_superposition(state: bool) -> void:
	if state:
		if not tetrimino.in_superposition:
			print("tetrimino_manager.gd: Putting the tetrimino in superposition!")
			tetrimino._toggle_superposition(state)
			in_superposition = state
	else:
		if tetrimino.in_superposition:
			print("tetrimino_manager.gd: Stopping superposition. Returning tetrimino to defaults.")
			tetrimino._toggle_superposition(state)
			in_superposition = state
	pass

# probability functions

func shuffle_all_probabilities() -> void:
	# var valid_rotations = Tetrimino.get_valid_rotations(t_shape)
	# if not rot_index in valid_rotations and valid_rotations.size() > 0:
	# 	rot_index = valid_rotations[0]
	tetrimino._shuffle_all_probs()
	probabilities = tetrimino._probabilities

func shift_probability_of(rot_index: int) -> void:
	var valid_rotations = Tetrimino.get_valid_rotations(t_shape)
	if not rot_index in valid_rotations and valid_rotations.size() > 0:
		tetrimino._shift_prob_of(rot_index)
		probabilities[rot_index] = tetrimino._probabilities[rot_index]

func reset_probabilities() -> void:
	# Reset to equal probabilities for all valid rotations
	var valid_rotations = Tetrimino.get_valid_rotations(t_shape)
	var prob_value = 1.0 / valid_rotations.size() if valid_rotations.size() > 0 else 1.0
	
	var new_probs = [0.0, 0.0, 0.0, 0.0]
	for i in range(valid_rotations.size()):
		new_probs[i] = prob_value
	
	probabilities = new_probs

# internal functions
func _on_probabilities_changed(new_probs: Array) -> void:
	probabilities = new_probs
	probabilities_changed.emit(new_probs)
