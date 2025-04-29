extends Control

@export var lesson_scene_1: PackedScene
@export var lesson_scene_2: PackedScene

@export var button1: Button
@export var button2: Button

func _ready():
	button1.connect("pressed", Callable(self, "_on_button1_pressed"))
	button2.connect("pressed", Callable(self, "_on_button2_pressed"))
	if Global.unlocked_level < 2:
		button2.disabled = true
		button2.modulate = Color(1, 1, 1, 0.4)
# Refactored handler with zero duplication
func _change_to_lesson(scene: PackedScene, button_name: String):
	if scene:
		print("%s: Successfully assigned scene" % button_name)
		get_tree().change_scene_to_packed(scene)
	else:
		print("❌ %s: Scene not assigned." % button_name)


func _on_button1_pressed():
	SaveGlobal.save_progress(lesson_scene_1.resource_path)
	_change_to_lesson(lesson_scene_1, "Button 1")

func _on_button2_pressed():
	SaveGlobal.save_progress(lesson_scene_2.resource_path)
	_change_to_lesson(lesson_scene_2, "Button 2")
