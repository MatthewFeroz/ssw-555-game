@tool
extends Sprite2D

@export var color: Color = Color.WHITE:
	set(new_color):
		color = new_color
		modulate = color

func _ready():
	modulate = color
