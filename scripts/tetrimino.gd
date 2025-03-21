@tool
extends Node2D

var blocks_container: Node2D
const BLOCK_SCENE = preload("res://scenes/block.tscn")
enum Shape {O, I, T, L, J, S, Z}
@export var tetrimino_shape = Shape.O:
	set(new_shape):
		tetrimino_shape = new_shape
		if !Engine.is_editor_hint(): # only update in editor
			generate_tetrimino()

const BLOCK_SIZE = 128.0 # TODO: dynamically define block size instead of hard coding it


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
		[0.0, 0.0],
		[0.0, 1.0],
		[1.0, 0.0],
		[1.0, 1.0],
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
		[0.0, 0.0],
		[0.0, 1.0],
		[0.0, 2.0],
		[0.0, 3.0],
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
		[1.0, 0.0],
		[0.0, 1.0],
		[1.0, 1.0],
		[2.0, 1.0],
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
		[2.0, 0.0],
		[0.0, 1.0],
		[1.0, 1.0],
		[2.0, 1.0],
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
		[0.0, 0.0],
		[0.0, 1.0],
		[1.0, 1.0],
		[2.0, 1.0],
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
		[1.0, 0.0],
		[2.0, 0.0],
		[0.0, 1.0],
		[1.0, 1.0],
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
		[0.0, 0.0],
		[1.0, 0.0],
		[1.0, 1.0],
		[2.0, 1.0],
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
	# get rid of existing blocks first
	for block in get_children():
		block.queue_free()

	var shape = TETRIMINOS[tetrimino_shape]
	var color = shape["color"]

	for coord in shape["coords"]:
		var block = BLOCK_SCENE.instantiate()
		block.position = Vector2(
			coord[0] * BLOCK_SIZE,
			coord[1] * BLOCK_SIZE
		)
		block.set_block_color(color)
		add_child(block)

func _ready() -> void:
	#blocks_container = get_node_or_null("Blocks")
	#print("Block container in _ready(): ", blocks_container)
	#if blocks_container == null:
		## push_error("ERROR: Blocks node is missing!")
		## return
		#blocks_container = Node2D.new()
		#blocks_container.name = "Blocks"
		#add_child(blocks_container)
	
	if !Engine.is_editor_hint():
		call_deferred("generate_tetrimino")
