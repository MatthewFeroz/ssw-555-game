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
var can_fall: bool = true	# will be false if the TetriminoManager is a child of a TetriminoPreview
var in_superposition: bool = false
var _shape: String
var _block_size: float
var _rotation_index: int
var _valid_rotations: Array
var _probabilities: Array
var _accum_delta: float	# accumulated delta; will only be used when in superposition

# built-in functions
func _ready() -> void:
	_shape = tetrimino_manager.t_shape
	_block_size = tetrimino_manager.block_size
	_rotation_index = tetrimino_manager.rotation_index
	_valid_rotations = get_valid_rotations(_shape)
	_probabilities = []
	_probabilities.resize(_valid_rotations.size())
	_probabilities.fill(1.0 / _valid_rotations.size())

func _process(delta) -> void:
	# don't do anything if the game isn't actually running
	if Engine.is_editor_hint():
		return

	if in_superposition:
		# add up the delta until accum_delta >= probability @ rotation_index
		# when that happens, schedule the next rotation and reset the accum_delta
		_accum_delta += delta
		#print("accumulated delta: " + str(_accum_delta))
		if _accum_delta >= _probabilities[_rotation_index]:
			_schedule_next_rotation()
			_accum_delta = 0.0

	if Input.is_action_just_pressed("ui_up"):
		tetrimino_manager.toggle_superposition(false)
	if Input.is_action_just_pressed("ui_down"):
		tetrimino_manager.toggle_superposition(true)

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
			_lock()

# custom functions


# getter functions
func get_blocks() -> Node2D:
	return $Blocks

"""
This static function returns an array with each possible rotation that the 
tetrimino can be. The rotation value will be 0, 90, 180, or 270(!!) so ensure 
that you convert them into the correct rotation indexes when needed.
"""
static func get_valid_rotations(t_shape: String) -> Array:
# at most, there's 4 different rotations
	match t_shape:
		# O-shape has only 1 rotation
		"O":
			return [0]
		# these shapes only have 2 rotations, 0° or 90°
		"I", "S", "Z":
			return [0, 90]
		# these can have all 4 rotations
		"T", "L", "J":
			return [0, 90, 180, 270]
		_:
			printerr("Invalid shape!")
			return []

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
func _schedule_next_rotation() -> void:
	var new_index = (_rotation_index + 1) % _valid_rotations.size()
	_set_rotation_index_to(new_index)

func _set_rotation_index_to(
	new_index: int
) -> void:
	var curr_angle = self._rotation_index * 90
	print("tetrimino.gd: Current rotation: %d°" % curr_angle)
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])
	#var n_rotations = _valid_rotations.size()
	#var new_angle = clampi((curr_angle + rot_angle) % 360, _valid_rotations[0], _valid_rotations[n_rotations])

	# regenerate the tetrimino but with the new rotation
	#var new_rotation_index = clampi((new_angle / 90) % 4, 0, n_rotations - 1)
	var new_rotation_index = new_index % _valid_rotations.size()
	tetrimino_manager.spawn_tetrimino(self._shape, self._block_size, new_rotation_index)
	self._rotation_index = new_rotation_index

	print("tetrimino.gd: New angle: %d°" % (self._rotation_index * 90))
	#force_in_bounds()
	print("tetrimino.gd: Current position: (%.1f, %.1f)" % [$Blocks.global_position.x, $Blocks.global_position.y])

func _lock() -> void:
	locked = true
	falling = false
	print("tetrimino.gd: Locked the Tetrimino. It will no longer be able to move.")

	# emit the signal for locked tetriminos and send the tetrimino's blocks
	var blocks: Array[Block] = []
	for block in $Blocks.get_children():
		blocks.append(block)
	lock_blocks.emit(blocks)

func _collapse() -> void:
	if can_fall and not falling:
		falling = true
		in_superposition = false	# collapsing == NO superposition!

func _toggle_superposition(state: bool) -> void:
	in_superposition = state
	_accum_delta = 0.0

func _shuffle_all_probs() -> void:
	var temp = _get_new_probs(100, _probabilities.size(), 5, 95)
	_probabilities = temp.map(func(elem): return elem / 100.0)

func _get_new_probs(
	total: int,
	k: int,
	min_val: int,
	max_val: int
) -> Array:
	"""
	turns out... this is pretty complicated compared to everything i've done. 
	the outcome of this function is essentially applying the Dirichlet 
	probability distribution to our probabilities. the available algorithms for 
	this are mostly just on Stack Overflow. using that (& GPT o3), i found the 
	following algorithm for calculating this:
	"""
	if k * min_val > total or k * max_val < total:
		printerr("Impossible bounds... Returning an empty array.")
		return []

	var slack: int = total - k * min_val
	var parts: Array = []
	parts.resize(k)
	parts.fill(0)

	while true:
		var cuts: Array = []
		cuts.resize(k - 1)
		cuts.fill(0)

		for i in range(cuts.size()):
			cuts[i] = randi_range(0, slack + 1)
		cuts.sort()

		var prev: int = 0
		var ok: bool = true
		for i in range(cuts.size()):
			parts[i] = min_val + (cuts[i] - prev)
			if parts[i] > max_val:
				ok = false
				break
			prev = cuts[i]

		parts[k - 1] = min_val + (slack - prev)
		if parts[k - 1] <= max_val and ok:
			break
	return parts

func _shift_prob_of(rot_index: int) -> void:
	# make sure that it's a possible rotation
	if rot_index >= 0 and rot_index < _probabilities.size():
		var base_prob = floori(_probabilities[rot_index] * 100)
		# the prob should only ever rise. it must rise by at least 10% to be worth it
		# also, the prob shouldn't be able to surpass 95% (or fall below 10%)
		var new_prob = clampi(randi_range(base_prob + 10, 95), 10, 95)
		_probabilities[rot_index] = new_prob / 100.0

		# for the remaining probs, do the following:
		"""
		1. get the indexes of the remaining probs (only really relevant if # of rotations > 2)
		2. filter the probs array into a new one without the base_prob
		3. calculate the difference between new prob and base prob
		4. divide the difference by the remaining probs
		4b. if there's a remainder from that result, while remainder > 0, subtract 1 from each prob in remaining
		5. shuffle the remaining
		6. for each index of remaining prob in the original, replace the original with the new prob
		"""
		var remaining_indexes = []
		var remaining_probs = []
		for i in range(_probabilities.size()):
			if i != rot_index:
				remaining_indexes.append(i)
				remaining_probs.append(_probabilities[i] * 100)
		var diff = new_prob - base_prob
		var quotient = diff / remaining_probs.size()
		remaining_probs = remaining_probs.map(func(elem): return elem - quotient)
		var remainder = (int)(diff) % remaining_probs.size()
		var tmp_idx = 0
		while remainder > 0:
			remaining_probs[tmp_idx] -= 1
			tmp_idx += 1
			remainder -= 1
		remaining_probs = remaining_probs.map(func(elem): return elem / 100)
		remaining_probs.shuffle()
		tmp_idx = 0
		for idx in remaining_indexes:
			_probabilities[idx] = remaining_probs[tmp_idx]
			tmp_idx += 1

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
