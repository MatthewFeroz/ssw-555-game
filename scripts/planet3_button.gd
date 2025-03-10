extends Button

@export var lesson_scene: PackedScene  # Drag your lesson scene here in the Inspector

func _on_pressed():
	if lesson_scene:
		get_tree().change_scene_to_packed(lesson_scene)  # Change to the lesson scene
