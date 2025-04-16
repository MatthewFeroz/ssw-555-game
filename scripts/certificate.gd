extends Node2D

@export var player_name: String = ""

@onready var name_label = $Control/Name
@onready var date_label = $Control/Date

func _ready():
	name_label.text = player_name
	date_label.text = "Date: " + Time.get_datetime_string_from_system()
