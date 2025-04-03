"""TODO:
	- add function that initializes the grid with blocks
		- find a way to save this array of blocks elsewhere later on
	- add function that forces the tetrmino to obey gravity
	- add function that clears lines
		- needs to remove all blocks
	- add function that resets the grid
	- ensure a signal is emitted when the entire grid is cleared out
"""

class_name Grid
extends Node2D

# constants
# grid related
const GRID_ORIGIN := Vector2(BLOCK_SIZE)
const GRID_WIDTH := 10
const GRID_HEIGHT := 20
const GRID_SIZE := GRID_WIDTH * GRID_HEIGHT

# block related
const BACKGROUND_COLOR := Color.DARK_GRAY
const BORDER_COLOR := Color.DIM_GRAY
const BLOCK_SIZE := Vector2(32.0, 32.0)	# all blocks must be 32x32

# tetrmino related
const TETRIMINO_SCENE_PATH := "res://scenes/mini_game_1/tetrimino.tscn"
const TETRIMINO_SCENE := preload(TETRIMINO_SCENE_PATH)
const SPAWN_POS := Vector2(GRID_WIDTH, 3)

# instance variables
var grid: Node2D
var grid_cells: Array
var grid_bg_container: Node2D
var border_container: Node2D
var tetrimino_shape: Tetrimino.Shape

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
	#print(grid_cells)
	
	# display the grid
	grid = Node2D.new()
	grid.name = "Grid"
	add_child(grid)
	
	# spawn in a brand new tetrimino
	if not tetrimino_shape:	# if the tetrmino wasn't already chosen, then pick a random one
		tetrimino_shape = Tetrimino.Shape.values().pick_random()
		#tetrimino_shape = DEFAULT_SHAPE
	spawn_tetrimino_in_grid(TETRIMINO_SCENE, tetrimino_shape, SPAWN_POS)
	
	# ensure that the tetrimino is in bounds
	var tetrimino = get_node("Tetrimino") as Tetrimino
	if tetrimino:
		tetrimino.out_of_bounds.connect(_on_Tetrimino_out_of_bounds)
	
func _draw() -> void:
	initialize_grid_border()
	initialize_grid_background()
	
# custom functions
static func grid_to_pixel(coord: Vector2) -> Vector2:
	return GRID_ORIGIN + (coord * BLOCK_SIZE.x)
	
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
					place_block(
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
					place_block(
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
			place_block(
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

func place_block(
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

func spawn_tetrimino_in_grid(
	tetrimino_scene: PackedScene,
	t_shape: Tetrimino.Shape,
	pos: Vector2 = SPAWN_POS
) -> void:
	var tetrimino = tetrimino_scene.instantiate()
	tetrimino.spawn_tetrimino(t_shape, BLOCK_SIZE.x)
	pos = grid_to_pixel(pos)
	tetrimino.position = pos
	add_child(tetrimino)
	tetrimino.check_bounds()

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
	var grid_width = GRID_WIDTH * BLOCK_SIZE.x
	var grid_height = GRID_HEIGHT * BLOCK_SIZE.x
	
	var left = bbox.x
	var right = bbox.y
	var top = bbox.z
	var bottom = bbox.w
	
	var diff
	match direction:
		Vector2.LEFT:
			print("grid_container.gd: Shifting the tetrimino to the left...")
			diff = right - (grid_origin.x + grid_width)
			tetrimino.global_position.x -= diff
		Vector2.RIGHT:
			print("grid_container.gd: Shifting the tetrimino to the right...")
			diff = grid_origin.x - left
			tetrimino.global_position.x += diff
		Vector2.UP:
			print("grid_container.gd: Shifting the tetrimino up...")
			diff = bottom - (grid_origin.y + grid_height)
			tetrimino.global_position.y -= diff
		Vector2.DOWN:
			print("grid_container.gd: Shifting the tetrimino down...")
			diff = grid_origin.y - top
			tetrimino.global_position.y += diff
	
	print("grid_container.gd: Updated the Tetrimino's position.")
	print("grid_container.gd: Tetrimino's current position: " + str(tetrimino.global_position))
