extends Node
func show_certificate():
	var player_name = "Lasya"  # Or get this from user input
	var cert_scene = preload("res://scenes/certificate.tscn").instantiate()
	cert_scene.player_name = player_name
	get_tree().root.add_child(cert_scene)

func _on_finish_button_pressed():
	show_certificate()
#incase of taking user input for name
var player_name = $LineEdit.text
