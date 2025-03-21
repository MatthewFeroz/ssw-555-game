extends Area2D

@onready var sprite: Sprite2D = $BlockSprite
var stored_color = Color.WHITE

func _ready() -> void:
	add_to_group("blocks")
	if sprite == null:
		push_error("BlockSprite node is missing!")
		return
		
	sprite.color = stored_color

func set_block_color(color: Color):
	stored_color = color
	if sprite:
		sprite.color = stored_color
