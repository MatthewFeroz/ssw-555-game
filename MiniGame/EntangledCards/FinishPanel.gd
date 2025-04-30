extends Control

signal finish_pressed()

@onready var final_label = $FinalLabel
@onready var finish_button = $FinishButton

func set_score(score: int):
	final_label.text = "🏁 Game Over!\nYour Score: %d" % score

func _ready():
	finish_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_scene1.tscn")
	)
	
