@tool
class_name TetriminoManager
extends Node

# signals
signal probabilities_changed(new_probs: Array)

# constants for tetrimino shape data
const TETRIMINO_SHAPES_PATH = "res://resources/shapes/tetrimino_shapes.tres"
const TETRIMINO_DATA = preload(TETRIMINO_SHAPES_PATH)	# tetrimino_shape: key, shape_data: value
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
var block_size: float = 128.0	# the original texture size is 128x128
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
	var tetrimino
	# if there's already an existing tetrimino, then all we're doing is getting 
	# rid of its blocks and updating it through this function
	# TODO: you're probably gonna remove this code eventually if you can confirm that this will always have a Tetrimino as its child
	var existing = get_node_or_null("Tetrimino") as Tetrimino
	if existing and existing is InstancePlaceholder:
		existing = existing.create_instance(true)
		existing.name = "Tetrimino"
	if existing:
		existing.clear_blocks()
		tetrimino = existing
	else:
		print("Here we created a new tetrimino!")
		tetrimino = Tetrimino.new()
		probabilities = tetrimino._probabilities
		if tetrimino.get_child_count() == 0:
			var blocks = Node2D.new()
			blocks.name = "Blocks"
			tetrimino.add_child(blocks)
		print(tetrimino.get_children())

	var blocks = tetrimino.get_blocks()
	#print(blocks)
	print(typeof(TETRIMINO_DATA["shapes"]))
	var shape_data = TETRIMINO_DATA["shapes"][shape_name]
	var coords = shape_data["coords"][rotation_index]
	var color = shape_data["color"]

	var block_num = 1
	for coord in coords:
		# create the block scene
		# print("tetrimino_manager.gd: Adding Block #" + str(block_num))
		var block = BLOCK_SCENE.instantiate()
		block.name = "Block %d" % block_num
		
		# change the block's color and size
		# print("tetrimino_manager.gd: Calling set_block_color() on block " + str(block) + ", with argument " + str(color))
		block.set_block_color(color)
		# print("tetrimino_manager.gd: Calling resize_block() on block " + str(block) + ", with argument " + str(TETRIMINO_BLOCK_SIZE))
		block.resize_block(block_size)
		
		# add the block to the Blocks node
		blocks.add_child(block)
		# makes the blocks visible in the editor
		if Engine.is_editor_hint():
			print("Adding " + block.name + " to the editor's scene tree.")
			block.owner = owner
		# print("tetrimino_manager.gd: Adding Block #" + str(block_num) + " to the scene")
		
		# position the block in the right place for the shape
		# print("tetrimino_manager.gd: Initial position of Block #" + str(block_num) + ": " + str(block.position))
		block.position = coord * block_size
		# print("tetrimino_manager.gd: Updated position of Block #" + str(block_num) + ": " + str(block.position))
		block_num += 1

		# ensure that the blocks are selectable nodes in the editor
		#if Engine.is_editor_hint():
			#add_child(tetrimino)
			#tetrimino.owner = self

	# ensure that tetriminos in an UI element cannot fall
	if is_child_of_preview():
		tetrimino.can_fall = false

	# set up a listener for when the probabilities change (if not already connected)
	if not tetrimino.probs_changed.is_connected(_on_probabilities_changed):
		tetrimino.probs_changed.connect(_on_probabilities_changed)

	# send out a signal that the tetrimino has been spawned
	#tetrimino.spawned.emit(tetrimino.global_position)
	tetrimino.tetrimino_manager = self	# ensure that it's not an orphan!
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

func shuffle_all_probabilities() -> void:
	tetrimino._shuffle_all_probs()
	probabilities = tetrimino._probabilities

func shift_probability_of(rot_index: int) -> void:
	tetrimino._shift_prob_of(rot_index)
	probabilities[rot_index] = tetrimino._probabilities[rot_index]

# internal functions
func _on_probabilities_changed(new_probs: Array) -> void:
	probabilities = new_probs
	probabilities_changed.emit(new_probs)
