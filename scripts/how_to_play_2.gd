extends Node2D


func _on_next_button_pressed(): 
	SaveGlobal.save_progress("res://MiniGame/EntangledCards/EntangledCards.tscn")
	get_tree().change_scene_to_file("res://MiniGame/EntangledCards/EntangledCards.tscn")
