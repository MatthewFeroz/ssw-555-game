extends Node
@onready var name_input = $NameInput
@onready var confirm_button = $ConfirmButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name != "":
		Global.user_name = name_input.text
		get_tree().change_scene_to_file("res://scenes/certificate.tscn")
	else:
		print("Please enter a name")
