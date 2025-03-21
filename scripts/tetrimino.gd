@tool
extends Node2D

enum Shape {O, I, T, L, J, S, Z}
@export var tetrimino_shape = Shape.O:
	set(new_shape):
		tetrimino_shape = new_shape


# original DS screen resolution = 256x192 (per screen)
# with both screens = 256x384
# size of entire O shape tetrimino = 20x20 (400px)
# size of a single block = 10x10 (100px)

# block_scaled up, what is the size of a single block?
# current viewport = 1920x1080 (16:9)
# original screen = 256x192 (4:3)
# when resizing the OG resolution to 1920x1440 (bc it maintains aspect ratio), i get a 77x77 size block
# let's round that up to 80x80

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

func convert_coords_to_rect(coords, block_scale) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for coord in coords:
		var rect = Rect2(
			coord[0] * block_scale,
			coord[1] * block_scale,
			block_scale,
			block_scale
		)

		rects.append(rect)
	return rects

func draw_shape(
	rects: Array[Rect2],
	starting_coords: Vector2,
	block_color: Color
) -> void:
	for rect in rects:
		# print(rect)
		rect.position += starting_coords
		draw_rect(rect, block_color)


func _draw() -> void:
	var block_scale = 80.0 # scale up block by 80 units
	var shape
	match tetrimino_shape:
		Shape.O:
			shape = O_SHAPE
		Shape.I:
			shape = I_SHAPE
		Shape.T:
			shape = T_SHAPE
		Shape.L:
			shape = L_SHAPE
		Shape.J:
			shape = J_SHAPE
		Shape.S:
			shape = S_SHAPE
		Shape.Z:
			shape = Z_SHAPE
	var rects = convert_coords_to_rect(shape["coords"], block_scale)
	draw_shape(rects, Vector2(0.0, 0.0), shape["color"])

	# all of this code below is to simply test drawing tetriminos to screen
	# var shapes = [
	#     O_SHAPE,
	#     I_SHAPE,
	#     T_SHAPE,
	#     L_SHAPE,
	#     J_SHAPE,
	#     S_SHAPE,
	#     Z_SHAPE,
	# ]
	# var starting_coords = Vector2(0.0, 0.0)

	# for shape in shapes:
	#     var rects = convert_coords_to_rect(shape["coords"], block_scale)
	#     # print(rects)
	#     draw_shape(rects, starting_coords, shape["color"])
	#     # TODO: figure out a good distance between shapes (for testing purposes)
	#     starting_coords.x += 250
