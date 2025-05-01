extends Control

signal finish_pressed()

@onready var final_label = $FinalLabel
@onready var finish_button = $FinishButton
@onready var finish_sound_player = $FinishSoundPlayer  # Reference to AudioStreamPlayer

func set_score(score: int):
	final_label.text = "🏁 Game Over!\nYour Score: %d" % score

func _ready():
	# Connect the finish button's press signal
	finish_button.pressed.connect(_on_finish_button_pressed)

func _on_finish_button_pressed():
	# Play the finish sound when the button is pressed
	finish_sound_player.play()

	
