extends Window

signal answer_submitted(selected_answer)

var correct_answer = []

func show_question(color: String, combo: Array) -> void:
	correct_answer = combo
	$QuestionLabel.text = "For color '%s', identify the missing values:\n%s" % [color, str(combo)]
	popup_centered()

# Example implementation: Suppose each Option button passes a string or array as answer.
# Below are simple callback functions.
func _on_Option1_pressed() -> void:
	emit_signal("answer_submitted", "Option 1")
	hide()

func _on_Option2_pressed() -> void:
	emit_signal("answer_submitted", "Option 2")
	hide()

func _on_Option3_pressed() -> void:
	emit_signal("answer_submitted", "Option 3")
	hide()
