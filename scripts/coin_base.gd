# Coin.gd
extends Area2D

signal coin_collected

func _on_body_entered(_body: Node2D) -> void:
	if _body.name == "Character":
		_body.score += 1
		ScoreManager.add_score(1)
		emit_signal("coin_collected")
		self.queue_free()
		print(_body.score)
		
