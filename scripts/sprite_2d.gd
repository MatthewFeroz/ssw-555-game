extends Sprite2D
@export var default_texture: Texture
@export var upgraded_texture: Texture

func _ready():
	if Global.unlocked_level >= 2:
		texture = upgraded_texture
	else:
		texture = default_texture
