@tool
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

func _ready() -> void:
	if Engine.is_editor_hint():
		update_block()
	
func create_block() -> void:
	# create the sprite, set its color, and resize it
	sprite = Sprite2D.new()
	sprite.name = "BlockSprite"
	sprite.texture = preload(TEX_PATH)
	set_block_color(color)
	resize_block(block_size)
	
	# add the collision
	collision = CollisionShape2D.new()
	collision.name = "BlockCollision"
	add_block_collision(block_size)
	
	# add the sprite and collision to the scene
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

func add_block_collision(new_size: float) -> void:
	block_size = new_size
	if collision:
		var rect_collision = RectangleShape2D.new()
		rect_collision.size = Vector2(new_size, new_size)
		collision.shape = rect_collision
		
func remove_block_collision() -> void:
	collision.disabled = true
