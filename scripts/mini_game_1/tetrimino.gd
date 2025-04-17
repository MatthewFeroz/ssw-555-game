@tool
class_name Tetrimino
extends Node2D

@onready var tetrimino_manager = get_parent()

# signals
#signal spawned(pos: Vector2)
signal out_of_bounds(direction: Vector2, bbox: Vector4)
signal lock_blocks(blocks: Array[Block])

# member variables
var locked: bool = false
var falling: bool = false
var _shape: String
var _block_size: float
var _rotation_index: int

# built-in functions
func _ready() -> void:
	_shape = tetrimino_manager.t_shape
	_block_size = tetrimino_manager.block_size
	_rotation_index = tetrimino_manager.rotation_index
		
func _process(_delta) -> void:
	# don't do anything if the game isn't actually running
	if Engine.is_editor_hint():
		return

	if not locked:
		if Input.is_action_just_pressed("ui_left"):
			handle_rotation(270)	# equivalent to -90°
		elif Input.is_action_just_pressed("ui_right"):
			handle_rotation(90)

func _physics_process(_delta: float) -> void:
	# don't do anything if the game isn't actually running
	if Engine.is_editor_hint():
		return

	if falling and not locked:
		# check if it's possible to move the tetrimino down a block
		# if so, move it!
		if can_move_down():
			# first, move the tetrimino down a block
			global_position.y += Grid.BLOCK_SIZE.y
			# then, check if we're in bounds
			# if so, great! if not, we'll snap to be inside the grid
			if not is_in_bounds():
				force_in_bounds()
		# if not, we should lock the tetrimino in place
		else:
			#global_position.y -= Grid.BLOCK_SIZE.y
			lock()

# custom functions

# getter functions
func get_blocks() -> Node2D:
	return $Blocks

# helper functions
func clear_blocks() -> void:
	if get_blocks().get_child_count() > 0:
		var block_num = 1
		for block in get_blocks().get_children():
			block.name = "DeletedBlock%d" % block_num
			block.queue_free()
			block_num += 1

#func get_block_positions() -> Array:
	#var positions = []
	#for block in get_blocks().get_children():
		#var grid_pos = Grid.pixel_to_grid(block.global_position)
		#positions.append(Vector2(floori(grid_pos.x), floori(grid_pos.y)))
	#return positions

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
			push_error("tetrimino.gd (force_in_bounds): Missing BlockSprite!")
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
	return bbox

# property modification functions
func handle_rotation(
	rot_angle: int
) -> void:
	var curr_angle = self._rotation_index * 90
	print("tetrimino.gd: Current rotation: %d°" % curr_angle)
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])
	var new_angle = (curr_angle + rot_angle) % 360

	# regenerate the tetrimino but with the new rotation
	var new_rotation_index = (new_angle / 90) % 4
	tetrimino_manager.spawn_tetrimino(self._shape, self._block_size, new_rotation_index)
	self._rotation_index = new_rotation_index

	print("tetrimino.gd: New angle: %d°" % (self._rotation_index * 90))
	#force_in_bounds()
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])

func lock() -> void:
	locked = true
	falling = false
	print("tetrimino.gd: Locked the Tetrimino. It will no longer be able to move.")

	# emit the signal for locked tetriminos and send the tetrimino's blocks
	var blocks: Array[Block] = []
	for block in $Blocks.get_children():
		blocks.append(block)
	lock_blocks.emit(blocks)

# collision detection functions
func can_move_down() -> bool:
	# if the tetrimino is already locked, then we're assuming it has been put
	# at its final resting place.
	if locked:
		return false

	# to test if it's possible to move the tetrimino down, we'll determine 
	# if it would theoretically overlap the blocks already on the grid OR if the
	# bottom is touching the grid's bottom
	var bbox = get_bbox()
	var max_y = Grid.GRID_ORIGIN.y + (Grid.GRID_HEIGHT * Grid.BLOCK_SIZE.y)
	if bbox.w >= max_y:
		return false
		
	var test_move = Vector2(0, Grid.BLOCK_SIZE.y)
	for block in $Blocks.get_children():
		var curr_pos = block.global_position	# uncomment this for debugging if needed
		var new_pos = curr_pos + test_move	# uncomment this for debugging if needed
		new_pos = Grid.pixel_to_grid(new_pos)
		var new_row_index = floori(new_pos.y)
		var new_col_index = floori(new_pos.x)
		#var new_pos = block.global_position + test_move
		var other_blocks = get_tree().get_nodes_in_group("blocks")
		for other in other_blocks:
			# if the other block doesn't belong to the same row as the 
			# tetrimino's block AFTER the test move, then it probably won't have
			# any effect on its collision detection at all
			var other_pos = other.global_position	# uncomment this for debugging if needed
			other_pos = Grid.pixel_to_grid(other_pos)
			var other_row_index = floori(other_pos.y)
			var other_col_index = floori(other_pos.x)
			if other.global_position.y != new_pos.y:
				continue

			# assuming the only blocks left are the ones in the same row of the 
			# tetrimino's block, all we need to do is see if they share the same
			# position. if so, they're overlapping, meaning that the tetrimino 
			# cannot move down.
			print("grid_container.gd: Other Block's Position: (%f, %f)" % [other_pos.x, other_pos.y])
			print("grid_container.gd: Test Move Position: (%f, %f)" % [new_pos.x, new_pos.y])
			if is_equal_approx(other.global_position.x, new_pos.x):
				return false

	return true

func is_in_bounds() -> bool:
	# check if the grid even exists in the scene tree. if it doesn't, then 
	# there's no point of checking if it's in bounds!
	var grid_container = get_node_or_null("/root/GridContainer") as Grid
	if not grid_container or grid_container.name != "GridContainer":
		return true

	var grid = grid_container.get_node("Grid") as Node2D
	if not grid:
		return true
	# find the bounding box of the tetrimino
	var bbox = get_bbox()
	var left = bbox.x
	var right = bbox.y
	var top = bbox.z
	var bottom = bbox.w

	# determine whether or not the tetrimino is out of bounds
	# return false if it is
	var grid_origin = Grid.grid_to_pixel(Vector2(0, 0))
	var grid_width = Grid.GRID_WIDTH * Grid.BLOCK_SIZE.x
	var grid_height = Grid.GRID_HEIGHT * Grid.BLOCK_SIZE.x

	if left < grid_origin.x:
		return false
	elif top < grid_origin.y:
		return false
	elif right > (grid_origin.x + grid_width):
		return false
	elif bottom > (grid_origin.y + grid_height):
		return false

	return true

func force_in_bounds() -> void:
	# check if the grid even exists in the scene tree. if it doesn't, then
	# there's no point of checking if it's in bounds!
	#var tree = get_tree_string()
	#print_tree()
	#if "GridContainer" not in get_tree_string():
		#return

	var grid_container = get_node_or_null("../..") as Grid
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

	# we also need to check if the tetrimino is capable of moving down. if it can move down, then we need to keep shifting it up until it can't anymore.
	if not locked and not can_move_down():
		out_of_bounds.emit(Vector2.UP, bbox)
	# otherwise, we need to determine whether or not the other sides of the tetrimino are out of bounds. we'll send a signal if they are
	else:
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
