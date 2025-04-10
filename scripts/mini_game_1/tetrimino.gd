"""TODO:
	- (4/8/25): refactor the out-of-bounds detection so that it shifts the tetrimino all at once IF multiple sides are out of bounds
		- add function that returns a boolean when the tetrimino is in bounds
	- (4/8/25): when the tetrimino is spawned, make sure it stays in bounds
		- emit the spawned signal whenever the tetrimino is generated
"""
@tool
class_name Tetrimino
extends Node2D

# signals
signal spawned(pos: Vector2)
signal out_of_bounds(direction: Vector2, bbox: Vector4)
signal locked_signal(blocks: Array[Block])

# constants for block scene
const BLOCK_SCENE_PATH = "res://scenes/mini_game_1/block.tscn"
const BLOCK_SCENE = preload(BLOCK_SCENE_PATH)

# inspector variables
enum Shape {O, I, T, L, J, S, Z}
@export var tetrimino_shape = Shape.O:
	set(new_shape):
		tetrimino_shape = new_shape
		if Engine.is_editor_hint():	# only update in editor
			generate_tetrimino()

const BLOCK_SIZE = 128.0	# the original texture size is 128x128
@export var tetrimino_block_size = BLOCK_SIZE:
	set(new_size):
		tetrimino_block_size = new_size
		if Engine.is_editor_hint():	# only update in editor
			generate_tetrimino()

# member variables
var locked: bool = false
#var __shape: Shape
#var __block_size := Vector2(BLOCK_SIZE, BLOCK_SIZE)

# below are the shapes in unit form (as in, not scaled)
# to understand coordinates, imagine each shape is in a 3x3 cell

# O-Shape
"""
[
	(0,0),
	(1,0),
	(0,1),
	(1,0),
]
"""
const O_SHAPE: Dictionary = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
	],
	"pivot": Vector2(0.5, 0.5),
	"color": Color.YELLOW,
}

# I-Shape
"""
[
	(0,0),
	(0,1),
	(0,2),
	(0,3),
]
"""
const I_SHAPE: Dictionary = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(0.0, 2.0),
		Vector2(0.0, 3.0),
	],
	"pivot": Vector2(-0.5, 1.5),
	"color": Color.CYAN
}

# T-Shape
"""
[
	(1,0),
	(0,1),
	(1,1),
	(2,1),
]
"""
const T_SHAPE: Dictionary = {
	"coords": [
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
	"pivot": Vector2(1.0, 1.0),
	"color": Color.PURPLE
}

# L-Shape
"""
[
	(2,0),
	(0,1),
	(1,1),
	(2,1),
]
"""
const L_SHAPE: Dictionary = {
	"coords": [
		Vector2(2.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
	"pivot": Vector2(1.0, 1.0),
	"color": Color.ORANGE
}

# J-Shape
"""
[
	(0,0),
	(0,1),
	(1,1),
	(2,1),
]
"""
const J_SHAPE: Dictionary = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
	"pivot": Vector2(1.0, 1.0),
	"color": Color.BLUE
}

# S-Shape
"""
[
	(1,0),
	(2,0),
	(1,0),
	(1,1),
]
"""
const S_SHAPE: Dictionary = {
	"coords": [
		Vector2(1.0, 0.0),
		Vector2(2.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
	],
	"pivot": Vector2(1.0, 1.0),
	"color": Color.LIME
}

# Z-Shape
"""
[
	(0,0),
	(1,0),
	(1,1),
	(2,1),
]
"""
const Z_SHAPE: Dictionary = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
	"pivot": Vector2(1.0, 1.0),
	"color": Color.RED
}

const TETRIMINOS: Dictionary = {
	Shape.O: O_SHAPE,
	Shape.I: I_SHAPE,
	Shape.T: T_SHAPE,
	Shape.L: L_SHAPE,
	Shape.J: J_SHAPE,
	Shape.S: S_SHAPE,
	Shape.Z: Z_SHAPE
}

func spawn_tetrimino(
	t_shape: Shape = tetrimino_shape,
	block_size: float = tetrimino_block_size
) -> void:	
	generate_tetrimino(t_shape, block_size)
	check_bounds()

func get_shape_data() -> Dictionary:
	var shape
	match tetrimino_shape:
		Shape.O:
			shape = O_SHAPE
		Shape.I:
			shape = I_SHAPE
		Shape.T:
			shape = T_SHAPE
		Shape.J:
			shape = J_SHAPE
		Shape.L:
			shape = L_SHAPE
		Shape.S:
			shape = S_SHAPE
		Shape.Z:
			shape = Z_SHAPE
	return shape

func generate_tetrimino(
	t_shape: Shape = tetrimino_shape,
	block_size: float = tetrimino_block_size
) -> Tetrimino:
	# get rid of existing blocks first
	for block in $Blocks.get_children():
		block.queue_free()

	var shape = TETRIMINOS[t_shape]
	var color = shape["color"]
	var pivot = shape["pivot"]

	var block_num = 1
	for coord in shape["coords"]:
		# create the block scene
		# print("tetrimino.gd: Adding Block #" + str(block_num))
		var block = BLOCK_SCENE.instantiate()
		block.name = "Block %d" % block_num
		
		# change the block's color and size
		# print("tetrimino.gd: Calling set_block_color() on block " + str(block) + ", with argument " + str(color))
		block.set_block_color(color)
		# print("tetrimino.gd: Calling resize_block() on block " + str(block) + ", with argument " + str(tetrimino_block_size))
		block.resize_block(block_size)
		
		# add the block to the Blocks node
		$Blocks.add_child(block)
		# print("tetrimino.gd: Adding Block #" + str(block_num) + " to the scene")
		
		# position the block in the right place for the shape
		# print("tetrimino.gd: Initial position of Block #" + str(block_num) + ": " + str(block.position))
		block.position = (coord - pivot) * block_size
		# print("tetrimino.gd: Updated position of Block #" + str(block_num) + ": " + str(block.position))
		block_num += 1
		
		# make sure to lock the tetrimino in place if collision with other 
		# blocks or it reaches the grid's bottom
		block.lock_tetrimino.connect(_on_Block_locked)
		
		# ensure that the blocks are selectable nodes in the editor
		if Engine.is_editor_hint():
			$Blocks.set_editable_instance(block, true)
	
	# send out a signal that the tetrimino has been spawned
	#spawned.emit(self.global_position)
	return self

func handle_rotation(
	rot_angle: float
) -> void:
	print("tetrimino.gd: Current rotation: %.2f°" % $Blocks.rotation_degrees)
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])
	print("tetrimino.gd: New angle: %.2f" % ($Blocks.rotation_degrees + rot_angle))
	
	$Blocks.rotation_degrees = (int)($Blocks.rotation_degrees + rot_angle) % 360
	print("tetrimino.gd: Current rotation: %.2f°" % $Blocks.rotation_degrees)
	check_bounds()
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])

func get_bbox() -> Vector4:
	# find the bounding box of the tetrimino
	var left = INF
	var right = -INF
	var top = INF
	var bottom = -INF
	#var block_size = Grid.get_block_size()
	#print("Block size: ", Grid.BLOCK_SIZE.x)
	
	for block in $Blocks.get_children():
		var global_pos = block.global_position
		var sprite = block.get_node("BlockSprite")
		if not sprite:
			push_error("tetrimino.gd (check_bounds): Missing BlockSprite!")
			return Vector4()
		var block_size = sprite.texture.get_width() * sprite.scale
		
		# for each side, we need to subtract by the "extents" of the block.
		# this is because the block is centered at (0,0) in its own scene,
		# which means that the distance from the center to a block edge is
		# half the block size.
		# that's fine for the Tetrimino scene (centering the block at the 
		# top-left would be a problem!), but this introduces problems for the
		# bounding box calculation. without this adjustment, our bounding box 
		# would be half a block off for every single block. thus, we subtract 
		# by the extent (block_size / 2).
		var block_left = global_pos.x - (block_size.x / 2.0)
		var block_right = global_pos.x + (block_size.x / 2.0)
		var block_top = global_pos.y - (block_size.y / 2.0)
		var block_bottom = global_pos.y + (block_size.y / 2.0)
		
		left = min(left, block_left)
		right = max(right, block_right)
		top = min(top, block_top)
		bottom = max(bottom, block_bottom)
	
	var bbox = Vector4(
		left,
		right,
		top,
		bottom
	)
	print("Bounding box: ", bbox)
	return bbox
	

func check_bounds() -> void:
	# use the grid node to check if the tetrimino is in bounds
	var grid_container = get_parent() as Node2D
	if not grid_container or grid_container.name != "GridContainer":
		return
		
	var grid = grid_container.get_node("Grid") as Node2D
	if not grid:
		return
		
	# find the bounding box of the tetrimino
	var bbox = get_bbox()
	var left = bbox.x
	var right = bbox.y
	var top = bbox.z
	var bottom = bbox.w
	
	# determine whether or not the tetrimino is out of bounds
	# send a signal if it is
	var grid_origin = Grid.grid_to_pixel(Vector2(0, 0))
	var grid_width = Grid.GRID_WIDTH * Grid.BLOCK_SIZE.x
	var grid_height = Grid.GRID_HEIGHT * Grid.BLOCK_SIZE.x
	
	if left < grid_origin.x:
		out_of_bounds.emit(Vector2.RIGHT, bbox)
	elif top < grid_origin.y:
		out_of_bounds.emit(Vector2.DOWN, bbox)
	elif right > (grid_origin.x + grid_width):
		out_of_bounds.emit(Vector2.LEFT, bbox)
	elif bottom > (grid_origin.y + grid_height):
		out_of_bounds.emit(Vector2.UP, bbox)
		
	# if the tetrimino is at the bottom of the grid, LOCK IT
	if bottom >= (grid_origin.y + grid_height):
		lock()

func lock(
	block_collision: bool = false
) -> void:
	locked = true
	print("tetrimino.gd: Locked the Tetrimino. It will no longer be able to move.")
	
	# make sure the tetrimino is not overlapping IF it collided with a block
	if block_collision:
		position.y -= Grid.BLOCK_SIZE.y
	
	# emit the signal for locked tetriminos and send the tetrimino's blocks
	var blocks: Array[Block] = []
	for block in $Blocks.get_children():
		blocks.append(block)
	locked_signal.emit(blocks)

func _ready() -> void:
	if not Engine.is_editor_hint():
		if not get_parent() or get_parent().name == "Grid":
			generate_tetrimino()
		
func _process(_delta) -> void:
	# don't do anything if the game isn't actually running
	if Engine.is_editor_hint():
		return
	
	if not locked:
		if Input.is_action_just_pressed("ui_left"):
			#var rot_vector = Vector2.LEFT
			handle_rotation(-90)
		elif Input.is_action_just_pressed("ui_right"):
			#var rot_vector = Vector2.RIGHT
			handle_rotation(90)
		
#func _draw() -> void:
	#draw_circle(
		#Vector2.ZERO,
		#4,
		#Color.RED
	#)

func _on_Block_locked() -> void:
	lock(true)
