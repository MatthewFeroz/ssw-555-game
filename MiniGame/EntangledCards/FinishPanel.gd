extends Control

signal finish_pressed()

@onready var final_label = $FinalLabel
@onready var finish_button = $FinishButton
@onready var finish_sound_player = $FinishSoundPlayer

func set_score(score: int):
	final_label.text = "🏁 Game Over!\nYour Score: %d" % score
	ScoreManager.add_score(score)  # or total_score if that's the variable used

func _ready():
	finish_button.pressed.connect(_on_finish_button_pressed)

func _on_finish_button_pressed():
	print("Playing finish sound...")
	finish_sound_player.play()
	await get_tree().create_timer(1.0).timeout  # Wait 1 second for sound to play
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
