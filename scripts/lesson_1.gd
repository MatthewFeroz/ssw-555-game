extends Control


func _on_next_button_pressed():
	get_parent().visible = false  
	SaveGlobal.save_progress("res://scenes/howToPlay_1.tscn")
	get_tree().change_scene_to_file("res://scenes/howToPlay_1.tscn")
