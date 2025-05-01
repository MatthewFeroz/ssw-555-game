# NameInput.gd
extends Node

signal name_confirmed(player_name: String)

@onready var name_input = $NameInput
@onready var confirm_button = $ConfirmButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed():
	var player_name = name_input.text.strip_edges()
	if player_name != "":
		print("✅ Emitting signal with name:", player_name)
		emit_signal("name_confirmed", player_name)
		queue_free()  # Remove the scene after emitting
	else:
		print("❌ Name is empty.")
