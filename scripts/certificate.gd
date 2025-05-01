extends Node2D

@export var player_name: String = ""

@onready var name_label = $Control/Name
@onready var date_label = $Control/Date


func _ready():
	name_label.text = Global.user_name
	date_label.text = "Date: " + Time.get_datetime_string_from_system()


func _on_download_button_pressed() -> void:
	await get_tree().process_frame  # ensure full render before capture

	# Capture the certificate as image
	var img = get_viewport().get_texture().get_image()
	var path = "user://certificate.png"
	var result = img.save_png(path)
	if result == OK:
		print("✅ Certificate saved at:", path)

		# 🔓 Open the folder or the file automatically (optional)
		OS.shell_open(ProjectSettings.globalize_path("user://certificate.png"))
	else:
		print("❌ Failed to save certificate.")
