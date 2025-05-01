extends Node2D

@onready var color_rect = $ColorRect  # Reference the ColorRect

func _on_animation_player_animation_finished(anim_name: StringName):
	# Start the fade-out animation
	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 1, 1)  # Fade to black in 1.5 seconds
	tween.tween_callback(change_scene)  # Call function after fade-out

func change_scene():
	get_tree().change_scene_to_file("res://scenes/main_scene1.tscn")

func _on_music_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)
