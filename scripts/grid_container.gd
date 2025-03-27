extends Node2D

# constants
const BACKGROUND_COLOR = Color.DARK_GRAY
const BORDER_COLOR = Color.DIM_GRAY
const BLOCK_SIZE = Vector2(32.0, 32.0)	# all blocks must be 32x32

# instance variables
var grid: Node2D
var border: Node2D
var border_background: Node2D
var grid_width: int = 10
var grid_height: int = 20
var starting_pos = 2

func _ready() -> void:
	grid = Node2D.new()
	grid.name = "Grid"
	add_child(grid)
	
func _draw() -> void:
	initialize_grid_border()
	initialize_grid_background()
	
	
func place_block(
	container: Node2D,
	block_num: int,
	block_name: String,
	pos: Vector2,
	block_size: Vector2,
	color: Color,
	#remove_collision: bool = false
) -> void:
	# create the block
	#print("Position of block: " + str(pos))
	var block = ColorRect.new()
	block.name = block_name % block_num
	#var block = BLOCK_SCENE.instantiate()
	#block_container.name = block_name % block_num
	
	# resize it and give it a grey color
	block.size = block_size
	block.modulate = color
	#block_container.resize_block(block_size)
	#block_container.set_block_color(color)
	
	# add the block and position it correctly
	container.add_child(block)
	block.position = pos * block_size.x
	#grid.add_child(block_container)
	#block_container.add_child(block)
	#block.position = pos * block_size

func initialize_grid_border() -> void:
	var block_num = 1
	var block_container = Node2D.new()
	block_container.name = "GridBorder"
	var sides = {
		"top": {
			"x": [-1, grid_width + 1],
			"y": starting_pos - 1
		},
		"left": {
			"x": -1,
			"y": [0, grid_height]
		},
		"right": {
			"x": grid_width,
			"y": [0, grid_height]
		},
		"bottom": {
			"x": [-1, grid_width + 1],
			"y": grid_height + starting_pos
		},
	}
	
	for side in sides:
		var pos: Vector2
		var side_container = Node2D.new()
		side_container.name = "Border%s" % side.capitalize()
		#print("Current side: " + side)
		match side:
			"top", "bottom":
				for i in range(sides[side]["x"][0], sides[side]["x"][1]):
					pos = Vector2(i + starting_pos, sides[side]["y"])
					#print("Placing block at current position: " + str(pos))
					place_block(
						side_container,
						block_num,
						"BorderBlock%d",
						pos,
						BLOCK_SIZE,
						BORDER_COLOR
					)
					block_num += 1

			"left", "right":
				for i in range(sides[side]["y"][0], sides[side]["y"][1]):
					pos = Vector2(sides[side]["x"] + starting_pos, i + starting_pos)
					#print("Placing block at current position: " + str(pos))
					place_block(
						side_container,
						block_num,
						"BorderBlock%d",
						pos,
						BLOCK_SIZE,
						BORDER_COLOR
					)
					block_num += 1
					
		block_container.add_child(side_container)
	grid.add_child(block_container)

func initialize_grid_background() -> void:
	var block_num = 1
	var block_container = Node2D.new()
	block_container.name = "GridBackground"
	for x in range(grid_width):
		var grid_row = Node2D.new()
		grid_row.name = "GridRow%d" % (x + 1)
		for y in range(grid_height):
			var pos = Vector2(x + starting_pos, y + starting_pos)
			#print("initialize_grid_background: Placing block at current position: " + str(pos))
			place_block(
				grid_row,
				block_num,
				"BGBlock%d",
				pos,
				BLOCK_SIZE,
				BACKGROUND_COLOR,
				#true
			)
			block_num += 1
		block_container.add_child(grid_row)
	grid.add_child(block_container)
