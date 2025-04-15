"""TODO:
	- (4/15/25): add a listener that resets the game once the user selects "Restart"
	- (4/15/25): create an UI that allows the user to select the piece
	- (4/15/25): create an UI that allows the user to select the rotation they want to use to solve the puzzle
	- (4/15/25): create an UI that displays the current probability distributions
	- (4/15/25): add functions for the quantum computing gates that change the probabilities
	- (4/15/25): ensure that the UI for selecting the rotation ONLY appears for the T/S-gate
	- (4/15/25): add a points system (should utilize signals, BTW) that's based on the correct pieces & rotations
	- (4/15/25): make sure to wait for user input to progress to the next puzzle!
	- (4/15/25): create a screen transition for loading the new puzzle
	- (4/15/25): create all of the other puzzles (maybe 5 puzzles?)
"""

class_name MiniGame1
extends Node

@onready var grid_container = $Game/GridContainer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if grid_container.total_blocks == 0:
			reset_game()

func reset_game() -> void:
	print("mini_game_1.gd: Restarting the game!")
	grid_container.reset_grid()
