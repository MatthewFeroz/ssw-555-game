@tool
class_name Block
extends Node2D

# constants
const TEX_PATH: String = "res://assets/sprites/Tetromino_Block.svg"

# exported variables
@export var block_size: float = 128.0: # the original texture size is 128x128
	set(new_size):
		if block_size != new_size:
			block_size = new_size
			if Engine.is_editor_hint():
				update_block()

@export var color: Color = Color.WHITE:
	set(new_color):
		if color != new_color:
			color = new_color
			if Engine.is_editor_hint():
				update_block()

# instance variables
var sprite: Sprite2D
var collision: CollisionShape2D

func _init() -> void:
	# print("block.gd: Initializing Block scene. Calling create_block()...")
	create_block()

func _ready() -> void:
	if Engine.is_editor_hint():
		update_block()
	
func create_block() -> void:
	# create the sprite, set its color, and resize it
	# print("block.gd: Creating Sprite2D with the name 'BlockSprite'.")
	sprite = Sprite2D.new()
	sprite.name = "BlockSprite"
	sprite.texture = preload(TEX_PATH)
	# print("block.gd: Setting the block color to " + str(color))
	set_block_color(color)
	# print("block.gd: Setting the block size to " + str(block_size))
	resize_block(block_size)
	
	# add the collision
	# print("block.gd: Creating CollisionShape2D with the name 'BlockCollision'.")
	collision = CollisionShape2D.new()
	collision.name = "BlockCollision"
	add_block_collision(block_size)
	
	# add the sprite and collision to the scene
	# print("block.gd: Adding 'BlockSprite' and 'BlockCollision' to the Block scene.")
	add_child(sprite)
	add_child(collision)

func update_block():
	for child in get_children():
		child.queue_free()

	create_block()
	
func set_block_color(new_color: Color) -> void:
	color = new_color
	if sprite:
		sprite.modulate = new_color

func resize_block(new_size: float) -> void:
	block_size = new_size
	if sprite:
		var scale_factor = new_size / 128.0 # the original texture size is 128x128
		sprite.scale = Vector2(scale_factor, scale_factor)
		if collision:
			collision.shape.size = Vector2(scale_factor, scale_factor)

func add_block_collision(new_size: float) -> void:
	block_size = new_size
	if collision:
		var rect_collision = RectangleShape2D.new()
		rect_collision.size = Vector2(new_size, new_size)
		collision.shape = rect_collision
		
func remove_block_collision() -> void:
	collision.disabled = true
