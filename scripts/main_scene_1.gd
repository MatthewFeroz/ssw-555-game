extends Node2D

@onready var color_rect = $ColorRect  # Reference the ColorRect node

var coins_collected = 0
@onready var score_label = $Coins/TotalScore  # Change to your actual node path

func _ready():
	# Fade in the scene by animating the alpha of the ColorRect
	var tween = get_tree().create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 1.5)  # Fade out the black screen in 1.5 seconds
	update_score_display()
	
	# Connect the signal from all existing coins in the scene
	for coin in get_tree().get_nodes_in_group("coins"):
		if coin.is_connected("coin_collected", Callable(self, "_on_coin_collected")) == false:
			coin.connect("coin_collected", Callable(self, "_on_coin_collected"))
	
func _on_coin_collected() -> void:
	print("Coin collected")	
	print("Main scene received coin_collected signal!") 
	update_score_display()

func _on_music_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)

func update_score_display():
	score_label.text = "Total Points: " + str(ScoreManager.total_score)
