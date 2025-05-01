# Main.gd
extends Node

func _ready():
	var name_input_scene = load("res://scenes/NameInput.tscn").instantiate()
	add_child(name_input_scene)
	
	# Connect to the signal
	name_input_scene.connect("name_confirmed", _on_name_confirmed)

func _on_name_confirmed(player_name):
	print("🔁 Switching to Certificate Scene with name:", player_name)
	
	# Load and pass the name
	var cert_scene = load("res://scenes/certificate.tscn").instantiate()
	cert_scene.player_name = player_name

	# Clean current children
	for child in get_children():
		child.queue_free()

	add_child(cert_scene)
