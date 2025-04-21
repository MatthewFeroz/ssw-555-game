extends Node2D

@onready var color_rect = $ColorRect  # Reference the ColorRect node

func _ready():
	# Fade in the scene by animating the alpha of the ColorRect
	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 1.5)  # Fade out the black screen in 1.5 seconds
