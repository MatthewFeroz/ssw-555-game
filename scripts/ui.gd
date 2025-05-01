extends CanvasLayer

func update_label(value: int) -> void:
	$Control/HBoxContainer/Label.tex = str(value)
