extends Node

var total_score: int = 0

func add_score(points: int) -> void:
	total_score += points

func reset_score() -> void:
	total_score = 0
