extends Area2D
@export var scene_path: String = ""
@export var level_number := 1 

func _ready():
	if level_number > Global.unlocked_level:
		modulate = Color(1, 1, 1, 0.4)
		set_deferred("monitoring", false)
	else:
		set_deferred("monitoring", true)

func _on_body_entered(body):
	if body.name == "Character" and level_number <= Global.unlocked_level:
		var final_scene = scene_path if scene_path != "" else "res://scenes/mini_game_%d.tscn" % level_number
		get_tree().change_scene_to_file(final_scene)
