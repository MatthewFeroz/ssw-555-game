extends Control

@onready var instruction_label: Label = $InstructionLabel

func set_instruction_text(text: String) -> void:
	instruction_label.text = text
