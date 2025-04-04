extends Control


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/intro_anim.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_music_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)
