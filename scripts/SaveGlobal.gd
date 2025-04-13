extends Node

var save_path := "user://save_data.json"
var current_scene_path := ""
# var player_points := 0

func save_progress(scene_path: String):
	current_scene_path = scene_path
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var data = {"scene": scene_path}
				#, "points": player_points,}
	file.store_string(JSON.stringify(data))

func load_progress() -> String:
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		if typeof(data) == TYPE_DICTIONARY:
			current_scene_path = data.get("scene", "")
			#player_points = data.get("points", 0)
	return current_scene_path
