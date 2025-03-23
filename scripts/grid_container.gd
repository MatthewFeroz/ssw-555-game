extends Node2D

# constants
const BLOCK_SCENE_PATH = "res://scenes/block.tscn"
const BLOCK_SCENE = preload(BLOCK_SCENE_PATH)
const BACKGROUND_COLOR = Color.DARK_GRAY
const BORDER_COLOR = Color.DIM_GRAY
const BLOCK_SIZE = 32.0	# all blocks must be 32x32

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
	
	initialize_grid_border()
	initialize_grid_background()
	
	
func place_block(
	block_num: int,
	block_name,
	pos: Vector2,
	block_size: float,
	color: Color,
	remove_collision: bool = false
) -> void:
	# create the block
	var block = BLOCK_SCENE.instantiate()
	block.name = block_name % block_num
	
	# resize it and give it a grey color
	block.resize_block(block_size)
	block.set_block_color(color)
	
	# add the block and position it correctly
	grid.add_child(block)
	if remove_collision:
		block.remove_block_collision()	# we shouldn't have collision for the background blocks
	block.position = pos * block_size
	block_num += 1

func initialize_grid_border() -> void:
	var block_num = 1
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
		print("Current side: " + side)
		match side:
			"top", "bottom":
				for i in range(sides[side]["x"][0], sides[side]["x"][1]):
					pos = Vector2(i + starting_pos, sides[side]["y"])
					#print("Placing block at current position: " + str(pos))
					place_block(
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
						block_num,
						"BorderBlock%d",
						pos,
						BLOCK_SIZE,
						BORDER_COLOR
					)
					block_num += 1

func initialize_grid_background() -> void:
	var block_num = 1
	for x in range(grid_width):
		for y in range(grid_height):
			place_block(
				block_num,
				"BGBlock%d",
				Vector2(x + starting_pos, y + starting_pos),
				BLOCK_SIZE,
				BACKGROUND_COLOR,
				true
			)
