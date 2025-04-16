extends Control

@export var player_name: String = ""

@onready var name_label = $NameLabel
@onready var date_label = $DateLabel

func _ready():
	name_label.text = player_name
	date_label.text = "Date: " + Time.get_datetime_string_from_system()
