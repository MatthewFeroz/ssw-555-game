"""TODO:
	- (4/8/25): refactor the out-of-bounds detection so that it shifts the tetrimino all at once IF multiple sides are out of bounds
		- add function that returns a boolean when the tetrimino is in bounds
	- (4/8/25): when the tetrimino is spawned, make sure it stays in bounds
		- emit the spawned signal whenever the tetrimino is generated
	- (4/10/25): prevent O-shape tetriminos from rotating (it's time to tackle this!)
"""
@tool
class_name Tetrimino
extends Node2D

# signals
signal spawned(pos: Vector2)
signal out_of_bounds(direction: Vector2, bbox: Vector4)
signal lock_blocks(blocks: Array[Block])

# constants for block scene
const BLOCK_SCENE_PATH = "res://scenes/mini_game_1/block.tscn"
const BLOCK_SCENE = preload(BLOCK_SCENE_PATH)

# inspector variables
enum Shape {O, I, T, L, J, S, Z}
@export var TETRIMINO_SHAPE = Shape.O:
	set(new_shape):
		TETRIMINO_SHAPE = new_shape
		if Engine.is_editor_hint():	# only update in editor
			generate_tetrimino()

const BLOCK_SIZE = 128.0	# the original texture size is 128x128
@export var TETRIMINO_BLOCK_SIZE = BLOCK_SIZE:
	set(new_size):
		TETRIMINO_BLOCK_SIZE = new_size
		if Engine.is_editor_hint():	# only update in editor
			generate_tetrimino()

# member variables
var locked: bool = false
var falling: bool = false
var _shape: Shape = TETRIMINO_SHAPE
var _block_size: float = TETRIMINO_BLOCK_SIZE

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

# built-in functions
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
			handle_rotation(270)	# equivalent to -90°
		elif Input.is_action_just_pressed("ui_right"):
			#var rot_vector = Vector2.RIGHT
			handle_rotation(90)

func _physics_process(_delta: float) -> void:
	if falling and not locked:
		# check if it's possible to move the tetrimino down a block
		# if so, move it!
		if can_move_down():
			# first, move the tetrimino down a block
			global_position.y += Grid.BLOCK_SIZE.y
			# then, check if we're in bounds
			# if so, great! if not, we'll snap to be inside the grid
			check_bounds()
		# if not, we should lock the tetrimino in place
		else:
			lock()

#func _draw() -> void:
	#draw_circle(
		#Vector2.ZERO,
		#4,
		#Color.RED
	#)

# custom functions

# creating tetriminos
func spawn_tetrimino(
	t_shape: Shape = _shape,
	block_size: float = _block_size
) -> void:
	generate_tetrimino(t_shape, block_size)
	check_bounds()

func generate_tetrimino(
	t_shape: Shape = _shape,
	block_size: float = _block_size
) -> Tetrimino:
	self._shape = t_shape
	self._block_size = block_size

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
		# print("tetrimino.gd: Calling resize_block() on block " + str(block) + ", with argument " + str(TETRIMINO_BLOCK_SIZE))
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

	$Blocks.rotation_degrees = 0
	# send out a signal that the tetrimino has been spawned
	#spawned.emit(self.global_position)
	return self

# getter functions
func get_shape_data() -> Dictionary:
	var shape
	match TETRIMINO_SHAPE:
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

func get_blocks() -> Node2D:
	return $Blocks

# helper functions
static func get_shape_from_index(index: int) -> Tetrimino.Shape:
	return Tetrimino.Shape.values()[index]

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

# property modification functions
func handle_rotation(
	rot_angle: float
) -> void:
	print("tetrimino.gd: Current rotation: %.2f°" % $Blocks.rotation_degrees)
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])
	# depending on the shape, you might have a limited number of orientations available to you
	match _shape:
		Shape.O:
			# there is only 1 possible orientation for this shape
			$Blocks.rotation_degrees = 0
			print("tetrimino.gd: New angle: %.2f°" % $Blocks.rotation_degrees)
		Shape.I, Shape.S, Shape.Z:
			# there's only 2 possible orientations for these shapes
			$Blocks.rotation_degrees = (int)($Blocks.rotation_degrees + rot_angle) % 180
			print("tetrimino.gd: New angle: %.2f°" % $Blocks.rotation_degrees)
		_:
			# this shape has 4 possible orientations
			$Blocks.rotation_degrees = (int)($Blocks.rotation_degrees + rot_angle) % 360
			print("tetrimino.gd: New angle: %.2f°" % $Blocks.rotation_degrees)

	print("tetrimino.gd: Current rotation: %.2f°" % $Blocks.rotation_degrees)
	check_bounds()
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])

func lock(
	block_collision: bool = false
) -> void:
	locked = true
	falling = false
	print("tetrimino.gd: Locked the Tetrimino. It will no longer be able to move.")
	
	# make sure the tetrimino is not overlapping IF it collided with a block
	if block_collision:
		position.y -= Grid.BLOCK_SIZE.y
	
	# emit the signal for locked tetriminos and send the tetrimino's blocks
	var blocks: Array[Block] = []
	for block in $Blocks.get_children():
		blocks.append(block)
	lock_blocks.emit(blocks)

# collision detection functions
func can_move_down() -> bool:
	# by testing if it's possible to move the tetrimino down, we'll determine 
	# if it would theoretically overlap the blocks already on the grid
	var test_move = Vector2(0, Grid.BLOCK_SIZE.y)
	for block in $Blocks.get_children():
		#var curr_pos = block.global_position	# uncomment this for debugging if needed
		#var new_pos = curr_pos + test_move	# uncomment this for debugging if needed
		var new_pos = block.global_position + test_move
		var other_blocks = get_tree().get_nodes_in_group("blocks")
		"""
		the only blocks we need to check are blocks which border any of the tetrimino's
		check if any of the tetrimino's blocks overlap with these blocks we're testing, then return false
		or, in other words, if the bottoms of any tetrimino block would be touching the top of any locked blocks, return false
		
		how do we solve this issue?
		we need to use the x,y position of the tetrimino block AFTER the test move, for starters
		we need to determine if the locked blocks have the same y position as one of the tetrimino's post-test move blocks
		if they do, then they'll be in the row of the tetrimino block we're checking collision for
		next, we need to see if any of those blocks have the same x position as of one of the post-test move blocks
		if so, then they're overlapping; thus, the tetrimino cannot move
		else, it can move down
		"""
		for other in other_blocks:
			# if the other block doesn't belong to the same row as the 
			# tetrimino's block AFTER the test move, then it probably won't have
			# any effect on its collision detection at all
			if other.global_position.y != new_pos.y:
				continue

			# assuming the only blocks left are the ones in the same row of the 
			# tetrimino's block, all we need to do is see if they share the same
			# position. if so, they're overlapping, meaning that the tetrimino 
			# cannot move down.
			#var other_pos = other.global_position	# uncomment this for debugging if needed
			#print("grid_container.gd: Other Block's Position: (%f, %f)" % [other_pos.x, other_pos.y])
			#print("grid_container.gd: Test Move Position: (%f, %f)" % [new_pos.x, new_pos.y])
			if is_equal_approx(other.global_position.x, new_pos.x):
				return false

	return true

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

# internal functions
func _on_Block_locked() -> void:
	lock(true)
