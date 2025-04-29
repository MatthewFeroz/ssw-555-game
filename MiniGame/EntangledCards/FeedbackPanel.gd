extends Control

signal next_pressed()

@onready var result_label = $ResultLabel
@onready var next_button = $NextButton

func show_result(is_correct: bool):
	visible = true
	if is_correct:
		result_label.text = "✅ Correct! +10 pts"
	else:
		result_label.text = "❌ Sorry, that was wrong. +0 pts"

func _ready():
	next_button.pressed.connect(func():
		visible = false
		emit_signal("next_pressed")
	)
