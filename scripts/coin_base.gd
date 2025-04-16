extends Area2D

signal coin_collected


func _on_body_entered(_body: Node2D) -> void:
	coin_collected.emit()
	print ("Player Entered")
