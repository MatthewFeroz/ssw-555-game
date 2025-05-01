extends Control


func _on_next_button_pressed():
	Global.unlocked_level = max(Global.unlocked_level, 2)
	SaveGlobal.save_progress("res://scenes/howToPlay_1.tscn")
	get_tree().change_scene_to_file("res://scenes/howToPlay_1.tscn")
