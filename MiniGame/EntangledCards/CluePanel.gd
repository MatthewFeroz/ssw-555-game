# CluePanel.gd
extends Control

@onready var round_label: Label = $BackgroundBox/VBox/RoundLabel
@onready var red_group_label: Label = $BackgroundBox/VBox/RedGroupLabel
@onready var green_group_label: Label = $BackgroundBox/VBox/GreenGroupLabel
@onready var blue_group_label: Label = $BackgroundBox/VBox/BlueGroupLabel

func set_clue_text(red_text: String, green_text: String, blue_text: String, round_number: int) -> void:
	round_label.text = "Round %d" % round_number
	red_group_label.text = "Red Group: " + red_text
	green_group_label.text = "Green Group: " + green_text
	blue_group_label.text = "Blue Group: " + blue_text

func show_clue(duration: float) -> void:
	visible = true
	await get_tree().create_timer(duration).timeout
	visible = false
