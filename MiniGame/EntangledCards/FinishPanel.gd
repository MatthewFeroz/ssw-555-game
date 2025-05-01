extends Control

signal finish_pressed()

@onready var final_label = $FinalLabel
@onready var finish_button = $FinishButton

func set_score(score: int):
	final_label.text = "🏁 Game Over!\nYour Score: %d" % score
	ScoreManager.add_score(score)  # or total_score if that's the variable used

func _ready():
	finish_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_scene1.tscn")
	)
	
