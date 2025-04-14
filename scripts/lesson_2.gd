extends Node2D


func _on_next_button_pressed():
	SaveGlobal.save_progress("res://scenes/howToPlay_2.tscn")
	get_tree().change_scene_to_file("res://scenes/howToPlay_2.tscn")
