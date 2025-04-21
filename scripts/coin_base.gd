extends Area2D

signal coin_collected

@onready var sound_player = $AudioStreamPlayer2D

func _on_body_entered(_body: Node2D) -> void:
	if _body.name == "Character":
		_body.score += 1
		sound_player.play()  # Play the sound!
		self.queue_free()
		print(_body.score)
		
