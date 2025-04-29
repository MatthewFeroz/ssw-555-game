extends Control

signal answer_selected(is_correct: bool)

@onready var question_label = $VBoxContainer/QuestionLabel
@onready var option_buttons := [
	$VBoxContainer/OptionA,
	$VBoxContainer/OptionB,
	$VBoxContainer/OptionC,
	$VBoxContainer/OptionD
]
@onready var submit_button = $VBoxContainer/SubmitButton

var correct_option := ""  # Will be set dynamically, like "B", "C", etc.
var selected_option := ""

func _ready():
	for button in option_buttons:
		button.pressed.connect(_on_option_selected.bind(button.name))
	submit_button.pressed.connect(_on_submit_pressed)

func set_question(text: String, options: Dictionary, correct: String):
	question_label.text = text
	correct_option = correct
	selected_option = ""
	for key in options.keys():
		var btn = get_node("VBoxContainer/Option" + key)
		btn.text = key + ". " + options[key]
		btn.button_pressed = false

func _on_option_selected(option_name: String):
	selected_option = option_name.replace("Option", "")
	for btn in option_buttons:
		btn.button_pressed = (btn.name == "Option" + selected_option)

func _on_submit_pressed():
	if selected_option == "":
		return # no selection
	var is_correct = (selected_option == correct_option)
	emit_signal("answer_selected", is_correct)
