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

# ...
@onready var grid_container = $Game/GridContainer
@onready var puzzle_manager = $Game/PuzzleManager

# member variables
var puzzle
var solution

func _ready() -> void:
	# for now, let's just get a random puzzle
	#var puzzle = puzzle_manager.get_random_puzzle()
	puzzle = puzzle_manager.get_puzzle_by_name("puzzle_1")
	solution = puzzle_manager.get_puzzle_solution_by_name(puzzle.puzzle_name)
	if puzzle:
		grid_container.initialize_grid(puzzle.starting_blocks)
		# for the solution, we'll always grab the first element
		var t_shape = Tetrimino.get_shape_from_index(solution.solution_list[0]["shape"])
		var spawn_pos = solution.solution_list[0]["spawn_pos"]
		var rot_angle = solution.solution_list[0]["rotation"]
		grid_container.spawn_new_tetrimino(t_shape, spawn_pos, rot_angle)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if grid_container.total_blocks == 0:
			reset_game()

func spawn_next_tetrimino(remaining_tetriminos: int) -> void:
	if remaining_tetriminos > 0:
		# for the solution, we'll always grab the first element
		solution.solution_list.pop_front()
		var t_shape = Tetrimino.get_shape_from_index(solution.solution_list[0]["shape"])
		var spawn_pos = solution.solution_list[0]["spawn_pos"]
		var rot_angle = solution.solution_list[0]["rotation"]
		# make sure to free the current tetrimino and spawn in a new one
		var tetrimino = get_node_or_null("Game/GridContainer/Tetrimino")
		if tetrimino:
			grid_container._free_and_spawn(tetrimino, t_shape, spawn_pos, rot_angle)

func reset_game() -> void:
	print("mini_game_1.gd: Restarting the game!")
	grid_container.reset_grid()
