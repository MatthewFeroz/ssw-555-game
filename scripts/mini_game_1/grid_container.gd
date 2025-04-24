"""TODO:
	- (4/12/25): make it impossible to spawn new tetriminos once there is no more space to spawn blocks
	- (4/12/25): make it impossible to spawn new tetriminos once all blocks have been cleared
	- (4/13/25): ensure that it will reset the grid when the user restarts the puzzle via the pause menu
"""

class_name Grid
extends Node2D

# signals
signal line_clear(cleared_row_index: int)
signal grid_clear
signal spawn_tetrimino(remaining_tetriminos: int)
signal update_score(score: int)

# constants for the grid
const GRID_ORIGIN := Vector2(BLOCK_SIZE)
const GRID_WIDTH := 10
const GRID_HEIGHT := 20
const GRID_SIZE := GRID_WIDTH * GRID_HEIGHT

# constants for blocks (background & physical)
const BACKGROUND_COLOR := Color.DARK_GRAY
const BORDER_COLOR := Color.NAVY_BLUE
const BLOCK_SIZE := Vector2(32.0, 32.0)	# all blocks must be 32x32

# constants for out-of-bounds detection
const MAX_X = GRID_WIDTH * BLOCK_SIZE.x
const MAX_Y = GRID_HEIGHT * BLOCK_SIZE.y

# constants for the tetrimino
const TETRIMINO_SCENE_PATH := "res://scenes/mini_game_1/tetrimino.tscn"
const TETRIMINO_SCENE := preload(TETRIMINO_SCENE_PATH)
const SPAWN_POS := Vector2(floor(GRID_WIDTH / 2), 0)

# instance variables
# grid related
var grid: Node2D
var grid_cells: Array[Array]	# each cell stores the block IDs
var grid_bg_container: Node2D
var border_container: Node2D
var total_blocks = 0

# puzzle related
#var puzzle_path: String
var puzzle: Array
var puzzle_num = 1
var tetrimino_count = 3	# typically, there's only 3 tetriminos for a given solution

# inspector variables
@export_enum("O", "I", "T", "L", "J", "S", "Z") var DEFAULT_SHAPE := "O"
@export var DEFAULT_SPAWN_POS := SPAWN_POS
@export_enum("0°", "90°", "180°", "270°") var DEFAULT_ROTATION: int = 0
@export_file("*.tres") var DEFAULT_PUZZLE_PATH := "res://resources/puzzles/test_grid_clear_puzzle.tres"

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
	# if we're running this in the main game, then the Puzzle Manager will get 
	# and set the puzzle data for us
	var puzzle_manager = get_parent().get_node_or_null("PuzzleManager")
	# otherwise, we use the testing line clear puzzle as the default
	if not puzzle_manager:
		var puzzle_res = load(DEFAULT_PUZZLE_PATH)
		initialize_grid(puzzle_res.starting_blocks)
		#initialize_grid([])

	# spawn in a brand new tetrimino
	# if we're running this in the main game, then the Puzzle Manager will spawn
	# in the tetrimino for us
	if not puzzle_manager:
		# otherwise, we'll use the default tetrimino shape
		var tetrimino_shape = DEFAULT_SHAPE
		#tetrimino_shape = Tetrimino.Shape.T
		# if the tetrmino wasn't already chosen, then pick a random one
		#tetrimino_shape = Tetrimino.Shape.values().pick_random()
		spawn_new_tetrimino(tetrimino_shape, DEFAULT_SPAWN_POS)

func _draw() -> void:
	initialize_grid_border()
	initialize_grid_background()

func _process(_delta: float) -> void:
	var tetrimino_manager = get_node_or_null("TetriminoManager") as TetriminoManager
	if not tetrimino_manager:
		return

	var tetrimino = tetrimino_manager.get_tetrimino()
	if not tetrimino.is_in_bounds():
		tetrimino.force_in_bounds()

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
	puzzle_data: Array
) -> void:
	# if the puzzle hasn't been set yet, then set it!
	if not puzzle:
		puzzle = puzzle_data

	for row in puzzle_data:
		for block in row:
			if block.has("color"):
				place_block(block["pos"], block["color"])
			else:
				# choose a random color if one wasn't provided
				var random_color = Block.VALID_COLORS[randi() % Block.VALID_COLORS.size()]
				place_block(block["pos"], random_color)

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

	# now, we need to add the Block to the corresponding Node that represents 
	# the row
	block.name = "Block[%d][%d]" % [row_index, col_index]
	var grid_row_name = "BlockRow%d" % row_index
	var grid_row = locked_blocks.get_node_or_null(grid_row_name)
	if not grid_row:
		grid_row = Node2D.new()
		grid_row.name = "BlockRow%d" % row_index
		locked_blocks.add_child(grid_row)
	grid_row.add_child(block)

func spawn_new_tetrimino(
	t_shape: String = DEFAULT_SHAPE,
	spawn_pos: Vector2 = DEFAULT_SPAWN_POS,
	t_rotation: int = DEFAULT_ROTATION	# this is the rotation index! (range: 0 and 3)
) -> void:
	spawn_tetrimino_in_grid(TETRIMINO_SCENE, t_shape, spawn_pos, t_rotation * 90)
	_connect_new_tetrimino_signals()

func spawn_tetrimino_in_grid(
	tetrimino_scene: PackedScene,
	t_shape: String = DEFAULT_SHAPE,
	pos: Vector2 = DEFAULT_SPAWN_POS,
	rot_angle: int = DEFAULT_ROTATION
) -> void:
	var tetrimino_manager = tetrimino_scene.instantiate()
	tetrimino_manager.name = "TetriminoManager"
	tetrimino_manager.t_shape = t_shape
	tetrimino_manager.block_size = BLOCK_SIZE.x
	# there are only 4 rotations for tetriminos, so we'll coerce the rotation 
	# to be one of these rotation indexes
	tetrimino_manager.rotation_index = (rot_angle / 90) % 4
	add_child(tetrimino_manager)	# spawns the actual tetrimino
	
	var tetrimino = tetrimino_manager.get_tetrimino()
	pos = grid_to_pixel(pos)
	# we need to do this because the spawn position of the Tetrimino node and 
	# the top-left block are a block-width apart, meaning that the spawn 
	# position will always be off by 1 without correction
	pos.x -= BLOCK_SIZE.x
	# let's make sure it's aligned with the grid
	tetrimino.global_position = pos
	align_tetrimino(tetrimino)
	#while not tetrimino.is_in_bounds():
		#tetrimino.force_in_bounds()

	#var block_positions = tetrimino_manager.get_block_positions()
	#for block_pos in block_positions:
		#print("grid_container: Block at grid:", block_pos)


func align_tetrimino(
	tetrimino: Tetrimino
) -> void:
	# we shouldn't rely on the tetrimino's position (because it's centered on 
	# the pivot point)
	var bbox = tetrimino.get_bbox()
	var actual_left = bbox.x
	var actual_top = bbox.z

	# now, we align the tetrimino based on its top-left corner
	# make sure to clamp it to the grid's playing area
	var expected_left = clampf(
		snappedf(actual_left, BLOCK_SIZE.x),
		GRID_ORIGIN.x, MAX_X)
	var expected_top = clampf(
		snappedf(actual_top, BLOCK_SIZE.y),
		GRID_ORIGIN.y, MAX_Y)
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

	# if all the blocks have been cleared, then emit a signal that the grid has 
	# been cleared
	if total_blocks == 0:
		grid_clear.emit()
	# else, for testing purposes, spawn the next tetrimino in the solution
	else:
		tetrimino_count -= 1
		spawn_tetrimino.emit(tetrimino_count)

func can_line_clear() -> bool:
	# look through all of the locked blocks
	var locked_blocks = get_node_or_null("LockedBlocks")
	if not locked_blocks:	# if there aren't any blocks, then return false
		return false

	# go through each row in the grid cells and check if any of the rows are
	# full
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

			# if the number of Nodes in this row is equal to the grid width,
			# then the row is full; thus, we can line clear
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
	# also emit a signal to update the score
	update_score.emit(GRID_WIDTH)
	
func reset_grid() -> void:
	# first, we clear out our internal grid cell structure
	grid_cells.clear()
	for y in range(GRID_HEIGHT):
		var grid_row = []
		for x in range(GRID_WIDTH):
			grid_row.append(null)
		grid_cells.append(grid_row)

	# next, remove all locked blocks from the scene
	var locked_blocks = get_node_or_null("LockedBlocks")
	if locked_blocks:
		locked_blocks.name = "DeletedLockedBlocks"
		for block_row in locked_blocks.get_children():
			block_row.queue_free()
		locked_blocks.queue_free()
	#print(total_blocks)

	# reinitialize the grid with the most recent puzzle
	#var puzzle_path	# TODO: generate the puzzle path based on the current puzzle number
	call_deferred("initialize_grid", puzzle)

	# finally, free the old tetrimino and spawn in a new one
	var tetrimino_manager = get_node_or_null("TetriminoManager") as TetriminoManager
	if tetrimino_manager:
		# free the tetrimino and spawn a new tetrimino
		call_deferred("_free_and_spawn", tetrimino_manager, DEFAULT_SHAPE, DEFAULT_SPAWN_POS, randi_range(0, 3), true)
	tetrimino_count = 3

func has_open_gaps() -> bool:
	var open_gap_found = false
	for col in range(GRID_HEIGHT - 1, -1, -1):
		# if we found an open gap, then return it
		if open_gap_found:
			break

		var row = grid_cells[col]
		# check if the row has any gaps
		var x = row.find(null)
		if x >= 0:
			# now, we need to ensure that it's an open one. let's assume it is
			open_gap_found = true
			for y in range(col - 1, -1, -1):
				var cell = grid_cells[y][x]
				if cell != null:	# if cell is not null, then the gap's not open
					open_gap_found = false
					break

	return open_gap_found

func find_open_gaps() -> Array:
	if not has_open_gaps():
		return []

	var spawn_col_candidates = []
	var open_gap_found = false
	for col in range(GRID_HEIGHT - 1, -1, -1):
		var row = grid_cells[col]
		# check if the row has any gaps
		var x = row.find(null)
		if x >= 0 and not spawn_col_candidates.has(x):
			# now, we need to ensure that it's an open one. let's assume it is
			open_gap_found = true
			for y in range(col - 1, -1, -1):
				var cell = grid_cells[y][x]
				if cell != null:	# if cell is not null, then the gap's not open
					open_gap_found = false
					break
			if open_gap_found:
				spawn_col_candidates.append(x)

	return spawn_col_candidates

# internal functions
"""
This function is responsible for updating the grid after a line clear. It 
*doesn't* clear any lines.
"""
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

#func _calculate_score(num_blocks: int) -> int:
	## TODO: move "get_block_count()" into this file instead of "mini_game_1.gd". make sure to call it here.
	#var total_num_blocks = get_tree().get_nodes_in_group("blocks").size()
	#"""
	#if we're clearing, then add the number of 
	#"""
	#return 10

func _free_and_spawn(
	tetrimino: TetriminoManager,
	new_t_shape = DEFAULT_SHAPE,
	new_spawn_pos = DEFAULT_SPAWN_POS,
	new_rot_angle = DEFAULT_ROTATION,
	spawn_new_piece = false
) -> void:
	# first, free the old tetrimino
	if is_instance_valid(tetrimino):
		tetrimino.name = "DeletedTetriminoManager"
		tetrimino.queue_free()

	# then, spawn a new tetrimino if desired
	if spawn_new_piece:
		spawn_new_tetrimino(
			new_t_shape,
			new_spawn_pos,
			new_rot_angle
		)

func _connect_new_tetrimino_signals():
	var tetrimino_manager = get_node_or_null("TetriminoManager") as TetriminoManager
	if tetrimino_manager:
		var tetrimino = tetrimino_manager.get_tetrimino()
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
	var tetrimino_manager = get_node_or_null("TetriminoManager") as TetriminoManager
	if not tetrimino_manager:
		return
	var tetrimino = tetrimino_manager.get_tetrimino()
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
			# OK so we actually need to check if we need to keep moving the
			# tetrimino up a block. there might be situations where the
			# tetrimino's y-position is the same as a block's.
			var grid_has_blocks = not get_tree().get_nodes_in_group("blocks").is_empty()
			while grid_has_blocks and not tetrimino.can_move_down():
				tetrimino.global_position.y -= BLOCK_SIZE.y
			# now, at the very least, the tetrimino's bottom will be touching
			# either the bottom of the grid OR it will be 2 rows above another
			# block (it's a weird bug that results from us assuming that the
			# tetrimino can only move *down* and not up). therefore, we need to
			# ensure that it's in the right position, and then lock and prevent
			# it from moving.
			if grid_has_blocks:
				tetrimino.global_position.y += BLOCK_SIZE.y
			tetrimino.lock()
		Vector2.DOWN:
			print("grid_container.gd: Shifting the tetrimino down...")
			border_start = grid_origin.y
			diff = border_start - top
			tetrimino.global_position.y += diff
	

	# TODO: place this in <oob-debug>.gd
	print("grid_container.gd: Updated the Tetrimino's position.")
	print("grid_container.gd: Tetrimino's current position: " + str(tetrimino.global_position))

func _on_Tetrimino_locked(
	blocks: Array[Block]
) -> void:
	# grab the tetrimino from the scene
	var tetrimino_manager = get_node("TetriminoManager") as TetriminoManager
	if not tetrimino_manager:
		return
	var tetrimino = tetrimino_manager.get_tetrimino()
	# ensure that the tetrimino is in bounds before we lock it for good!
	tetrimino.force_in_bounds()

	# a bit of a hacky solution: replace the tetrimino's blocks with new ones.
	# why? unfortunately we can't just add the tetrimino's blocks to the 
	# "blocks" group without causing issues with the collision detection code
	for block in blocks:
		call_deferred("place_block", pixel_to_grid(block.global_position), block.color)
		"""
		for every block from a locked piece added, we'll update the score by 1
		"""
		update_score.emit(1)
		block.queue_free()

	# now that the tetrimino's blocks are removed, free the tetrimino too (and
	# disconnect its signals!)
	if tetrimino.is_connected("out_of_bounds", _on_Tetrimino_out_of_bounds):
		tetrimino.disconnect("out_of_bounds", _on_Tetrimino_out_of_bounds)
	if tetrimino.is_connected("lock_blocks", _on_Tetrimino_locked):
		tetrimino.disconnect("lock_blocks", _on_Tetrimino_locked)

	# clear any lines if it's possible
	call_deferred("clear_lines")

	# free the tetrimino and spawn a new tetrimino (if testing in the "grid"
	# scene, make it random)
	var spawn_new_piece: bool = false
	var puzzle_manager = get_parent().get_node_or_null("PuzzleManager")
	if not puzzle_manager:
		spawn_new_piece = true
		var valid_shapes = TetriminoManager.get_valid_shapes()
		DEFAULT_SHAPE = valid_shapes[randi() % valid_shapes.size()]
	call_deferred("_free_and_spawn", tetrimino_manager, DEFAULT_SHAPE, DEFAULT_SPAWN_POS, randi_range(0, 3), spawn_new_piece)
