"""TODO:
	- (4/3/25): add function that resets the grid
	- (4/3/25): ensure a signal is emitted when the entire grid is cleared out
	- (4/8/25): when the tetrimino is spawned, make sure it stays in bounds
	- (4/9/25): for testing purposes, ensure that a new tetrimino is spawned when one gets locked
	- (4/12/25): make it impossible to spawn new tetriminos once there is no more space to spawn blocks
	- (4/12/25): make it impossible to spawn new tetriminos once all blocks have been cleared
	- (4/13/25): ensure that it will reset the grid when the user restarts the puzzle via the pause menu
"""

class_name Grid
extends Node2D

# signals
signal line_clear(cleared_row_index: int)

# constants
# grid related
const GRID_ORIGIN := Vector2(BLOCK_SIZE)
const GRID_WIDTH := 10
const GRID_HEIGHT := 20
const GRID_SIZE := GRID_WIDTH * GRID_HEIGHT
const DEFAULT_PUZZLE_PATH := "res://resources/puzzle_1.res"	# the default path to puzzle #1 resource

# block related
const BACKGROUND_COLOR := Color.DARK_GRAY
const BORDER_COLOR := Color.DIM_GRAY
const BLOCK_SIZE := Vector2(32.0, 32.0)	# all blocks must be 32x32

# out-of-bounds detection related(?)
const MAX_X = GRID_WIDTH * BLOCK_SIZE.x
const MAX_Y = GRID_HEIGHT * BLOCK_SIZE.y

# tetrmino related
const TETRIMINO_SCENE_PATH := "res://scenes/mini_game_1/tetrimino.tscn"
const TETRIMINO_SCENE := preload(TETRIMINO_SCENE_PATH)
#const SPAWN_POS := Vector2(floor(GRID_WIDTH / 2), 0)
const SPAWN_POS := Vector2(4, 0)

# instance variables
var grid: Node2D
var grid_cells: Array[Array]	# stores the block IDs
var puzzle: PuzzleResource
var grid_bg_container: Node2D
var border_container: Node2D
var tetrimino_shape: Tetrimino.Shape
var total_blocks = 0
var finished_clearing = false

# inspector variables
@export var DEFAULT_SHAPE := Tetrimino.Shape.O

# built-in functions
func _ready() -> void:
	# initialize the grid cells
	for y in range(GRID_HEIGHT):
		var grid_row = []
		for x in range(GRID_WIDTH):
			grid_row.append(null)
		grid_cells.append(grid_row)
		
	# make sure to update the grid when a line is cleared
	line_clear.connect(_on_Grid_line_clear)
	
	# display the grid
	grid = Node2D.new()
	grid.name = "Grid"
	add_child(grid)
	
	# initialize the grid with the starting blocks
	initialize_grid()
	
	# spawn in a brand new tetrimino
	tetrimino_shape = DEFAULT_SHAPE
	#tetrimino_shape = Tetrimino.Shape.T
	# if the tetrmino wasn't already chosen, then pick a random one
	#tetrimino_shape = Tetrimino.Shape.values().pick_random()
	spawn_new_tetrimino(tetrimino_shape)
	
func _draw() -> void:
	initialize_grid_border()
	initialize_grid_background()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		var tetrimino = get_node_or_null("Tetrimino") as Tetrimino
		if tetrimino and not tetrimino.falling:
			tetrimino.falling = true

# custom functions
static func grid_to_pixel(coord: Vector2) -> Vector2:
	coord.x = floori(coord.x)
	coord.y = floori(coord.y)
	return GRID_ORIGIN + (coord * BLOCK_SIZE.x)

static func pixel_to_grid(coord: Vector2) -> Vector2:
	return (coord - GRID_ORIGIN) / BLOCK_SIZE.x

static func get_block_size() -> Vector2:
	return BLOCK_SIZE

func initialize_grid_border() -> void:
	var block_num = 1
	border_container = Node2D.new()
	border_container.name = "GridBorder"
	var sides = {
		"top": {
			"x": range(-1, GRID_WIDTH + 1),
			"y": -1
		},
		"left": {
			"x": -1,
			"y": range(-1, GRID_HEIGHT + 1)
		},
		"right": {
			"x": GRID_WIDTH,
			"y": range(-1, GRID_HEIGHT + 1)
		},
		"bottom": {
			"x": range(-1, GRID_WIDTH + 1),
			"y": GRID_HEIGHT
		},
	}
	
	for side in sides:
		var pos: Vector2
		var side_coords = sides[side]
		var side_container = Node2D.new()
		side_container.name = "Border%s" % side.capitalize()
		#print("Current side: " + side)
		match side:
			"top", "bottom":
				var x_range = side_coords["x"]
				var y = side_coords["y"]
				for x in x_range:
					pos = Vector2(x, y)
					pos = grid_to_pixel(pos)
					#print("Placing block at current position: " + str(pos))
					place_bg_block(
						side_container,
						"BorderBlock%d" % block_num,
						pos,
						BLOCK_SIZE,
						BORDER_COLOR
					)
					block_num += 1

			"left", "right":
				var y_range = side_coords["y"]
				var x = side_coords["x"]
				for y in y_range:
					pos = Vector2(x, y)
					pos = grid_to_pixel(pos)
					#print("Placing block at current position: " + str(pos))
					place_bg_block(
						side_container,
						"BorderBlock%d" % block_num,
						pos,
						BLOCK_SIZE,
						BORDER_COLOR
					)
					block_num += 1
					
		border_container.add_child(side_container)
	grid.add_child(border_container)

func initialize_grid_background() -> void:
	var block_num = 1
	grid_bg_container = Node2D.new()
	grid_bg_container.name = "GridBackground"
	for x in range(GRID_WIDTH):
		var grid_row = Node2D.new()
		grid_row.name = "GridRow%d" % (x + 1)
		
		for y in range(GRID_HEIGHT):
			var pos = Vector2(x, y)
			pos = grid_to_pixel(pos)
			#print("initialize_grid_background: Placing block at current position: " + str(pos))
			place_bg_block(
				grid_row,
				"BGBlock%d" % block_num,
				pos,
				BLOCK_SIZE,
				BACKGROUND_COLOR,
				#true
			)
			block_num += 1
		grid_bg_container.add_child(grid_row)
	grid.add_child(grid_bg_container)

"""
Function for placing all grid blocks. These blocks will be behind the real blocks.
"""
func place_bg_block(
	container: Node2D,
	block_name: String,
	pos: Vector2,
	block_size: Vector2,
	color: Color,
) -> Vector2:
	# create the block
	#print("Position of block: " + str(pos))
	var block = ColorRect.new()
	block.name = block_name
	
	# resize it and set its color
	block.size = block_size
	block.modulate = color
	
	# add the block and position it correctly
	container.add_child(block)
	block.position = pos
	
	return block.position

func initialize_grid(
	path_to_puzzle: String = DEFAULT_PUZZLE_PATH
) -> void:
	puzzle = load(path_to_puzzle)
	var starting_blocks = puzzle.starting_blocks
	for row in starting_blocks:
		for block in row:
			place_block(block["pos"], block["color"])

func place_block(
	pos: Vector2,
	color: Color
) -> void:
	# create a new block
	var block = Block.new()
	block.resize_block(BLOCK_SIZE.x)
	block.add_block_collision(BLOCK_SIZE.x)
	block.set_block_color(color)
	block.add_to_group("blocks")	# add it to blocks group
	
	# since the block is centered at (0,0) in its own scene (distance from the 
	# center to a block edge is half the block size), this causes the block to 
	# be in the wrong position when we place it. thus, we need to offset it 
	# first before converting to grid coordinates.
	var offset = BLOCK_SIZE / 2
	pos = grid_to_pixel(pos)
	pos += offset
	
	# BTW, if the block was placed out of bounds, we shift it
	# TODO: keep detecting whether block is out of bounds until it's not
	# TODO: place this in <oob-detect>.gd
	var left = pos.x - (BLOCK_SIZE.x / 2.0)
	var right = pos.x + (BLOCK_SIZE.x / 2.0)
	var top = pos.y - (BLOCK_SIZE.y / 2.0)
	var bottom = pos.y + (BLOCK_SIZE.y / 2.0)
	
	var border_start
	var diff
	if left < GRID_ORIGIN.x:
		print("grid_container.gd: Shifting the block to the right...")
		border_start = GRID_ORIGIN.x
		diff = border_start - left
		pos.x += diff
	elif top < GRID_ORIGIN.y:
		print("grid_container.gd: Shifting the block down...")
		border_start = GRID_ORIGIN.y
		diff = border_start - top
		pos.y += diff
	elif right > (GRID_ORIGIN.x + MAX_X):
		print("grid_container.gd: Shifting the block to the left...")
		border_start = GRID_ORIGIN.x + MAX_X
		diff = right - border_start
		pos.x -= diff
	elif bottom > (GRID_ORIGIN.y + MAX_Y):
		print("grid_container.gd: Shifting the block up...")
		border_start = GRID_ORIGIN.y + MAX_Y
		diff = bottom - border_start
		pos.y -= diff
	
	block.position = pos
	
	# fill the corresponding grid cell
	fill_grid_cell(block)
	total_blocks += 1

func fill_grid_cell(
	block: Block
) -> void:
	# add the Block's id to the internal grid cells
	var cell_pos: Vector2 = pixel_to_grid(block.global_position)
	var row_index: int = floori(cell_pos.y)
	var col_index: int = floori(cell_pos.x)
	grid_cells[row_index][col_index] = block.get_instance_id()

	# add the Block to the screen under the LockedBlocks node
	var locked_blocks = get_node_or_null("LockedBlocks") as Node2D
	if not locked_blocks:
		locked_blocks = Node2D.new()
		locked_blocks.name = "LockedBlocks"
		add_child(locked_blocks)

	# now, we need to add the Block to the corresponding Node that represents the row
	block.name = "Block[%d][%d]" % [row_index, col_index]
	var grid_row_name = "BlockRow%d" % row_index
	var grid_row = locked_blocks.get_node_or_null(grid_row_name)
	if not grid_row:
		grid_row = Node2D.new()
		grid_row.name = "BlockRow%d" % row_index
		locked_blocks.add_child(grid_row)
	grid_row.add_child(block)

func spawn_new_tetrimino(
	t_shape: Tetrimino.Shape
) -> void:
	spawn_tetrimino_in_grid(TETRIMINO_SCENE, t_shape, SPAWN_POS)
	_connect_new_tetrimino_signals()

func spawn_tetrimino_in_grid(
	tetrimino_scene: PackedScene,
	t_shape: Tetrimino.Shape,
	pos: Vector2 = SPAWN_POS
) -> void:
	var tetrimino = tetrimino_scene.instantiate()
	tetrimino.name = "Tetrimino"
	tetrimino.spawn_tetrimino(t_shape, BLOCK_SIZE.x)
	pos = grid_to_pixel(pos)
	# let's make sure it's aligned with the grid
	tetrimino.position = pos
	align_tetrimino(tetrimino)
	add_child(tetrimino)
	tetrimino.check_bounds()

func align_tetrimino(
	tetrimino: Tetrimino
) -> void:
	# we shouldn't rely on the tetrimino's position (because it's centered on 
	# the pivot point)
	var bbox = tetrimino.get_bbox()
	var actual_left = bbox.x
	var actual_top = bbox.z
	
	# now, we align the tetrimino based on its top-left corner
	var expected_left = snappedf(actual_left, BLOCK_SIZE.x)
	var expected_top = snappedf(actual_top, BLOCK_SIZE.y)
	var diff = expected_left - actual_left
	tetrimino.position.x += diff
	diff = expected_top - actual_top
	tetrimino.position.y += diff

func clear_lines() -> void:
	var num_clearable_rows = find_num_clearable_rows()
	# clear any lines if it's possible
	while can_line_clear() and num_clearable_rows > 0:
		var row_index = find_first_clearable_row()
		clear_grid_row(row_index)
		num_clearable_rows -= 1

func can_line_clear() -> bool:
	# look through all of the locked blocks
	var locked_blocks = get_node_or_null("LockedBlocks")
	if not locked_blocks:	# if there aren't any blocks, then return false
		return false

	# go through each row in the grid cells and check if any of the rows are full
	for row_index in range(GRID_HEIGHT - 1, -1, -1):	# all the full rows will be at the botttom
		var grid_row_name = "BlockRow%d" % row_index
		var grid_row = locked_blocks.get_node_or_null(grid_row_name)
		if not grid_row:
			continue

		# if the number of Nodes in this row is equal to the grid width, then 
		# the row is full; thus, we can line clear
		if grid_row.get_child_count() == GRID_WIDTH:
			return true

	return false

func find_num_clearable_rows() -> int:
	if can_line_clear():
		var rows: Array[int] = []
		var locked_blocks = get_node_or_null("LockedBlocks")
		if not locked_blocks:	# if there aren't any blocks, then return 0
			return 0

		# go through each row in the grid cells and add the row index of the full rows
		for row_index in range(GRID_HEIGHT - 1, -1, -1):	# all the full rows will be at the botttom
			var grid_row_name = "BlockRow%d" % row_index
			var grid_row = locked_blocks.get_node_or_null(grid_row_name)
			if not grid_row:
				continue

			# if the number of Nodes in this row is equal to the grid width, then 
			# the row is full; thus, we can line clear
			if grid_row.get_child_count() == GRID_WIDTH:
				rows.append(row_index)

		return rows.size()
	else:
		return 0
func find_first_clearable_row() -> int:
	if can_line_clear():
		var locked_blocks = get_node_or_null("LockedBlocks")
		if not locked_blocks:	# if there aren't any blocks, then return 0
			return -1

		# go through each row in the grid cells and add the row index of the full rows
		for row_index in range(GRID_HEIGHT - 1, -1, -1):	# all the full rows will be at the botttom
			var grid_row_name = "BlockRow%d" % row_index
			var grid_row = locked_blocks.get_node_or_null(grid_row_name)
			if not grid_row:
				continue

			# if the number of Nodes in this row is equal to the grid width, then 
			# the row is full; thus, we can line clear
			if grid_row.get_child_count() == GRID_WIDTH:
				return row_index

	return -1	# return -1 if none of the rows are clearable

func clear_grid_row(
	row_index: int
) -> void:
	var locked_blocks = get_node_or_null("LockedBlocks")
	if not locked_blocks:	# if there aren't any blocks, then do nothing
		return
	
	# get the row in the scene tree and free all of its children
	var current_row_name = "BlockRow%d" % row_index
	var current_row = locked_blocks.get_node_or_null(current_row_name)
	if not current_row or current_row.get_child_count() == 0:
		return
	
	var deleted_block_count = 0
	for block in current_row.get_children():
		# rename and remove the block from the current row
		block.name = "DeletedBlock%d" % deleted_block_count
		current_row.remove_child(block)
		block.queue_free()
		total_blocks -= 1
		deleted_block_count += 1
	
	# update the grid cells to match
	var grid_row = grid_cells[row_index]
	for col_index in range(grid_row.size()):
		grid_cells[row_index][col_index] = null
	
	# now, emit the signal that a line has been cleared
	line_clear.emit(row_index)

# internal functions
func _on_Grid_line_clear(
	cleared_row_index: int
) -> void:
	# why GRID_WIDTH? because we deleted GRID_WIDTH blocks in clear_grid_row()
	var deleted_block_count = GRID_WIDTH

	# now, update the rest of grid (so that there's no gaps)
	var locked_blocks = get_node_or_null("LockedBlocks")
	if not locked_blocks:	# if there aren't any blocks, then do nothing
		return

	# look at each grid row that ISN'T empty
	# also, we will only look at rows *above* the cleared row
	for row_index in range(cleared_row_index - 1, -1, -1):
		var current_row_name = "BlockRow%d" % row_index
		var current_row = locked_blocks.get_node_or_null(current_row_name)
		if not current_row or current_row.get_child_count() == 0:
			continue

		# update the grid cells so that the contents of the current grid row are
		# empty. the contents of the row below will be filled by adding new 
		# blocks (see below).
		for col_index in range(GRID_WIDTH):
			# don't bother if the cell is empty anyways
			var cell = grid_cells[row_index][col_index]
			if cell:
				grid_cells[row_index][col_index] = null

		# just as in clear_grid_row(), we will free the children of this current
		# row. this time, though, we'll be using place_block() to ensure the 
		# block is put on the grid correctly
		for block in current_row.get_children():
			# before placing the new block, make sure to rename the old one
			block.name = "DeletedBlock%d" % deleted_block_count
			var current_grid_pos = pixel_to_grid(block.global_position)
			var col_index = floori(current_grid_pos.x)
			place_block(Vector2(col_index, row_index + 1), block.color)
			
			# now, remove the block from the current row
			current_row.remove_child(block)
			block.queue_free()
			total_blocks -= 1
			deleted_block_count += 1

func _free_and_spawn(tetrimino: Tetrimino) -> void:
	# first, free the old tetrimino
	if is_instance_valid(tetrimino):
		tetrimino.queue_free()

	# then, spawn a new tetrimino
	# if the tetrmino shape wasn't already chosen, then pick a random one	
	if not tetrimino_shape:
		tetrimino_shape = Tetrimino.Shape.values().pick_random()
	spawn_new_tetrimino(tetrimino_shape)

func _connect_new_tetrimino_signals():
	var tetrimino = get_node_or_null("Tetrimino") as Tetrimino
	if tetrimino:
		# ensure that the tetrimino is in bounds
		if not tetrimino.is_connected("out_of_bounds", _on_Tetrimino_out_of_bounds):
			tetrimino.out_of_bounds.connect(_on_Tetrimino_out_of_bounds)
		# add the blocks of a locked tetrimino to the grid
		if not tetrimino.is_connected("lock_blocks", _on_Tetrimino_locked):
			tetrimino.lock_blocks.connect(_on_Tetrimino_locked)

func _on_Tetrimino_out_of_bounds(
	direction: Vector2,
	bbox: Vector4
) -> void:
	print("grid_container.gd: The tetrimino is out of bounds.")
	# grab the tetrimino from the scene
	var tetrimino = get_node("Tetrimino") as Tetrimino
	if not tetrimino:
		return
	print("grid_container.gd: Tetrimino's current position: " + str(tetrimino.global_position))
	
	# determine whether or not the tetrimino is out of bounds
	var grid_origin = grid_to_pixel(Vector2(0,0))
	var grid_width = MAX_X
	var grid_height = GRID_HEIGHT * BLOCK_SIZE.x
	
	var left = bbox.x
	var right = bbox.y
	var top = bbox.z
	var bottom = bbox.w
	

	# TODO: place this in <oob-detect>.gd
	var diff
	var border_start
	match direction:
		Vector2.LEFT:
			print("grid_container.gd: Shifting the tetrimino to the left...")
			border_start = grid_origin.x + grid_width
			diff = right - border_start
			tetrimino.global_position.x -= diff
		Vector2.RIGHT:
			print("grid_container.gd: Shifting the tetrimino to the right...")
			border_start = grid_origin.x
			diff = border_start - left
			tetrimino.global_position.x += diff
		Vector2.UP:
			print("grid_container.gd: Shifting the tetrimino up...")
			border_start = grid_origin.y + grid_height
			diff = bottom - border_start
			tetrimino.global_position.y -= diff
		Vector2.DOWN:
			print("grid_container.gd: Shifting the tetrimino down...")
			border_start = grid_origin.y
			diff = border_start - top
			tetrimino.global_position.y += diff
	

	# TODO: place this in <oob-debug>.gd
	print("grid_container.gd: Updated the Tetrimino's position.")
	print("grid_container.gd: Tetrimino's current position: " + str(tetrimino.global_position))

func _on_Tetrimino_locked(
	blocks: Array[Block],
	block_collision: bool = false
) -> void:
	# grab the tetrimino from the scene
	var tetrimino = get_node("Tetrimino") as Tetrimino
	if not tetrimino:
		return

	# update the number of tetriminos spawned to the grid
	#num_locked_tetriminos += 1

	# a bit of a hacky solution: replace the tetrimino's blocks with new ones.
	# why? unfortunately we can't just add the tetrimino's blocks to the 
	# "blocks" group without causing issues with the collision detection code
	for block in blocks:
		call_deferred("place_block", pixel_to_grid(block.global_position), block.color)
		block.queue_free()

	# now that the tetrimino's blocks are removed, free the tetrimino too (and disconnect its signals!)
	if tetrimino.is_connected("out_of_bounds", _on_Tetrimino_out_of_bounds):
		tetrimino.disconnect("out_of_bounds", _on_Tetrimino_out_of_bounds)
	if tetrimino.is_connected("lock_blocks", _on_Tetrimino_locked):
		tetrimino.disconnect("lock_blocks", _on_Tetrimino_locked)

	# clear any lines if it's possible
	call_deferred("clear_lines")

	# spawn a new tetrimino (for testing, delete later)
	#call_deferred("_free_and_spawn", tetrimino)
	#tetrimino_shape = Tetrimino.Shape.values().pick_random()
	#call_deferred("spawn_tetrimino_in_grid", TETRIMINO_SCENE, tetrimino_shape, SPAWN_POS)
	#call_deferred("_connect_new_tetrimino_signals")
