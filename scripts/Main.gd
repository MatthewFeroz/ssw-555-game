extends Node

# Preload both scenes
var NameInputScene := preload("res://scenes/NameInput.tscn")
var CertificateScene := preload("res://scenes/certificate.tscn")

var name_input
var certificate

func _ready():
	# Instantiate and add NameInput scene
	name_input = NameInputScene.instantiate()
	add_child(name_input)

	# Connect the signal
	name_input.name_entered.connect(_on_name_entered)

func _on_name_entered(player_name: String):
	# Remove NameInput scene
	name_input.queue_free()

	# Instantiate and configure Certificate scene
	certificate = CertificateScene.instantiate()
	certificate.player_name = player_name  # Pass name to the certificate
	add_child(certificate)
