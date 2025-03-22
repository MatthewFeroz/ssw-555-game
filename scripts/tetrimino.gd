extends Node2D

# contants
const BLOCK_SCENE_PATH = "res://scenes/block.tscn"
const BLOCK_SCENE = preload(BLOCK_SCENE_PATH)

# exported variables
enum Shape {O, I, T, L, J, S, Z}
@export var tetrimino_shape = Shape.O:
	set(new_shape):
		tetrimino_shape = new_shape
		if !Engine.is_editor_hint():	# only update in editor
			generate_tetrimino()

const BLOCK_SIZE = 128.0	# the original texture size is 128x128
@export var block_size = BLOCK_SIZE:
	set(new_size):
		block_size = new_size


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
var O_SHAPE = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
	],
	"color": Color.YELLOW,
}

# I-Shape
"""
[
	(0,0),
	(0,1),
	(0,2),
	(0,3).
]
"""
var I_SHAPE = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(0.0, 2.0),
		Vector2(0.0, 3.0),
	],
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
var T_SHAPE = {
	"coords": [
		Vector2(1.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
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
var L_SHAPE = {
	"coords": [
		Vector2(2.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
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
var J_SHAPE = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
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
var S_SHAPE = {
	"coords": [
		Vector2(1.0, 0.0),
		Vector2(2.0, 0.0),
		Vector2(0.0, 1.0),
		Vector2(1.0, 1.0),
	],
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
var Z_SHAPE = {
	"coords": [
		Vector2(0.0, 0.0),
		Vector2(1.0, 0.0),
		Vector2(1.0, 1.0),
		Vector2(2.0, 1.0),
	],
	"color": Color.RED
}

var TETRIMINOS = {
	Shape.O: O_SHAPE,
	Shape.I: I_SHAPE,
	Shape.T: T_SHAPE,
	Shape.L: L_SHAPE,
	Shape.J: J_SHAPE,
	Shape.S: S_SHAPE,
	Shape.Z: Z_SHAPE
}

func generate_tetrimino() -> void:
	# prevent from running if scene is not fully loaded
	if !Engine.is_editor_hint() and !is_inside_tree():
		return
		
	# get rid of existing blocks first
	for block in $Blocks.get_children():
		block.queue_free()

	var shape = TETRIMINOS[tetrimino_shape]
	var color = shape["color"]

	var block_num = 1
	for coord in shape["coords"]:
		# create the block scene
		print("tetrimino.gd: Adding Block #" + str(block_num))
		var block = BLOCK_SCENE.instantiate()
		block.name = "Block %d" % block_num
		
		# change the block's color and size
		print("tetrimino.gd: Calling set_block_color() on block " + str(block) + ", with argument " + str(color))
		block.set_block_color(color)
		print("tetrimino.gd: Calling resize_block() on block " + str(block) + ", with argument " + str(block_size))
		block.resize_block(block_size)
		
		# add the block to the Blocks node
		$Blocks.add_child(block)
		print("tetrimino.gd: Adding Block #" + str(block_num) + " to the scene")
		
		# position the block in the right place for the shape
		print("tetrimino.gd: Initial position of Block #" + str(block_num) + ": " + str(block.position))
		block.position = coord * block_size
		print("tetrimino.gd: Updated position of Block #" + str(block_num) + ": " + str(block.position))
		block_num += 1
		
		# ensure that the blocks are selectable nodes in the editor
		if Engine.is_editor_hint():
			$Blocks.set_editable_instance(block, true)

func _ready() -> void:
	if !Engine.is_editor_hint():
		generate_tetrimino()
