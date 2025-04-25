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
@onready var puzzle_manager = $Game/PuzzleManager
@onready var tetrimino_selector = $UI/TetriminoSelector
@onready var score_node = $HBoxContainer2/ScoreCount
@onready var total_score: int = 0

# member variables
var puzzle: PuzzleResource
var solution: PuzzleSolution
var temp_solution_list: Array
var current_slot: Node = null
var selected_shape_name: String = ""
var selected_rotation_angle: int = 0

# constants
const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"
const TETRIMINO_SCENE = preload(TETRIMINO_SCENE_PATH)
const DEFAULT_PUZZLE_NAME = "puzzle_1"

func _ready() -> void:
# listen for score updates
	grid_container.update_score.connect(_on_score_update)
# getting tetrimino slots/shapes/rot
	for slot in get_tree().get_nodes_in_group("tetrimino_slots"):
		slot.connect("select", Callable(self, "_on_slot_selected"))

## logic for decreasing gate use number after someone presses button
# (rest of logic start at lines 309)
	update_gate_count()
	$sgate.pressed.connect(_on_use_gate_pressed)
	grid_container.update_score.connect(_on_score_update)

	# for now, let's just get a random puzzle (unless it's a test puzzle)
	puzzle = puzzle_manager.get_random_puzzle()
	while puzzle.puzzle_name.begins_with("test"):
		puzzle = puzzle_manager.get_random_puzzle()
	#puzzle = puzzle_manager.get_puzzle_by_name("puzzle_1")
	solution = puzzle_manager.get_puzzle_solution_by_name(puzzle.puzzle_name)
	# for testing purposes, let's also randomize the tetriminos in the solution
	temp_solution_list = get_randomized_solution(solution)
	#temp_solution_list = solution.solution_list.duplicate(true)
	if puzzle:
		grid_container.initialize_grid(puzzle.starting_blocks)
		# for the solution, we'll always grab the first element
		var t_shape = temp_solution_list[0]["shape"]
		var rot_angle: int
		# if the current tetrimino is the correct one, then use the solution's
		# spawn position and rotation. otherwise, dynamically determine the best
		# one
		var spawn_pos: Vector2
		if is_correct_solution_piece(t_shape):
			spawn_pos = temp_solution_list[0]["spawn_pos"]
			rot_angle = temp_solution_list[0]["rotation"]
		else:
			var result = determine_spawn_pos_and_rotation(t_shape) 
			spawn_pos = result[0]
			rot_angle = result[1]
		if tetrimino_selector:
			initialize_tetrimino_selector()
			grid_container.spawn_new_tetrimino(t_shape, spawn_pos, (rot_angle / 90) % 4)
	
	
	
	
	
	
	
	
	
	
	
	
	
	



## calculating points on interface
	#score_node = $HBoxContainer2/ScoreCount

func _on_slot_selected(shape_name: String, rotation_angle: int, slot_index: Node) -> void:
	if current_slot == slot_index:
		# Deselect if already selected
		slot_index.set_selected(false)
		current_slot = null
		selected_shape_name = ""
		selected_rotation_angle = 0
	else:
		# Deselect previous
		if current_slot:
			current_slot.set_selected(false)
		# Select new
		slot_index.set_selected(true)
		current_slot = slot_index
		selected_shape_name = shape_name
		selected_rotation_angle = rotation_angle

# gate uses UI logic
var gate_uses: int = 2
func _on_use_gate_pressed():
	if gate_uses > 0:
		gate_uses -= 1
		update_gate_count()

func update_gate_count():
	$HBoxContainer/GateCount.text = str(gate_uses)
	if gate_uses <= 0:
		$hgate.visible = false
		$sgate.visible = false
		
func _on_hgate_pressed() -> void:
	_on_use_gate_pressed()

func _on_score_update(new_score: int) -> void:
	total_score += new_score
	score_node.text = str(total_score)

func _on_collapse_pressed() -> void:
	var tetrimino_manager = grid_container.get_current_tetrimino()
	if tetrimino_manager:
		tetrimino_manager.collapse()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if grid_container.total_blocks == 0:
			reset_game()

func spawn_next_tetrimino(remaining_tetriminos: int) -> void:
	if remaining_tetriminos > 0:
		var t_shape: String = ""  # Declare variables here
		var rot_angle: int = 0    # Initialize them
		if selected_shape_name != "":
			t_shape = selected_shape_name
			rot_angle = selected_rotation_angle
		else:
			print("error loading tetrimino")
		var spawn_pos: Vector2 = Vector2(0, 0) # adjust as needed
		# Assuming there's a function like this:
		grid_container.spawn_tetrimino(t_shape, spawn_pos, rot_angle)
		
		#### didnt touch after here 4/25 JM
		
func reset_game() -> void:
	print("mini_game_1.gd: Restarting the game!")
	temp_solution_list = get_randomized_solution(solution)
	grid_container.reset_grid()

func get_randomized_solution(sol: PuzzleSolution) -> Array:
	var solution_list = sol.solution_list.duplicate(true)
	solution_list.shuffle()
	return solution_list

func initialize_tetrimino_selector() -> void:
	for i in range(temp_solution_list.size()):
		#var slot = TetriminoSlot.new()
		tetrimino_selector.set_tetrimino_slot(i, temp_solution_list[i]["shape"])
	tetrimino_selector._refresh_slots()
		#pass
		#tetrimino_selector.slots[i] = 

#Returns an Array with the best spawn position and best rotation as its elements.

func determine_spawn_pos_and_rotation(
	t_shape: String
) -> Array:
	if is_correct_solution_piece(t_shape):
		return solution.solution_list[0]["spawn_pos"]

	# we need to determine the best spawn first
	var best_score = INF
	var best_spawn = Vector2.ZERO	# fallback spawn position
	var best_rot_angle = 0	# fallback rotation

	# if there are any open gaps in the grid, then we'll be able to find an 
	# ideal spawn position
	if grid_container.has_open_gaps():
		# there might be multiple valid spawning positions, so let's figure out which one is the best
		var spawn_candidates = grid_container.find_open_gaps()
		# we'll do this by simulating dropping the tetrimino shape in each one 
		# of the spawning positions and calculating the score. whichever 
		# spawning position has the best score will be the one we use.
		for spawn_col in spawn_candidates:
			# the spawn position will be (spawn_col, 0)
			var spawn_pos = Vector2(spawn_col, 0)
			var result = evaluate_spawn_pos(t_shape, spawn_pos)
			var score = result[0]
			var rot_angle = result[1]
			# update spawn position if a better one was found
			if score < best_score:
				best_score = score
				best_spawn = spawn_pos
				best_rot_angle = rot_angle

	return [best_spawn, best_rot_angle]

"""
Returns an Array of the best score and the best rotation.
"""
func evaluate_spawn_pos(
	t_shape: String,
	spawn_pos: Vector2
) -> Array:
	var best_score = INF	# the lower the score, the better
	var best_rot_angle = 0

	# find the valid rotations for the tetrimino
	var valid_rotations = []
	for rot_angle in [0, 90, 180, 270]:	# at most, there's 4 different rotations
		match t_shape:
			# O-shape has only 1 rotation
			"O":
				if rot_angle == 0:
					valid_rotations.append(rot_angle)
			# these shapes only have 2 rotations, 0° or 90°
			"I", "S", "Z":
				if rot_angle == 0 or rot_angle == 90:
					valid_rotations.append(rot_angle)
			# these can have all 4 rotations
			"T", "L", "J":
				valid_rotations.append(rot_angle)

	# for each of the valid rotations, simulate dropping a tetrimino (a "ghost")
	# at the given spawn position and calculate the number of blocks in the grid
	# after line clearing
	for rot_angle in valid_rotations:
		var score = evaluate_spawn_pos_and_rotation(t_shape, spawn_pos, rot_angle)
		if score < best_score:
			best_score = score
			best_rot_angle = rot_angle
	return [best_score, best_rot_angle]

func evaluate_spawn_pos_and_rotation(
	t_shape: String,
	spawn_pos: Vector2,
	rot_angle: int
) -> int:
	var block_count = 0
	# create a "ghost" tetrimino manager
	var tetrimino_test = TETRIMINO_SCENE.instantiate()
	tetrimino_test.name = "GhostTetrimino"
	tetrimino_test.t_shape = t_shape
	tetrimino_test.block_size = Grid.BLOCK_SIZE.x
	tetrimino_test.rotation_index = (rot_angle / 90) % 4
	grid_container.add_child(tetrimino_test)

	# update the tetrimino's position and ensure it fits in the grid
	var ghost_tetrimino = tetrimino_test.get_tetrimino()
	ghost_tetrimino.visible = false	# make sure it's invisible
	# BTW, we need to shift the spawn position in the x position down by 1
	# because the spawn position of the Tetrimino node and the top-left block
	# are a block-width apart, meaning that the spawn position will always be
	# off by 1 without correction
	spawn_pos.x -= 1
	spawn_pos = Grid.grid_to_pixel(spawn_pos)
	ghost_tetrimino.position = spawn_pos
	grid_container.align_tetrimino(ghost_tetrimino)
	
	# simulate the tetrimino drop and get back the score (number of blocks in grid)
	block_count = simulate_and_evaluate_drop(ghost_tetrimino)
	# make sure to free the ghost tetrimino
	tetrimino_test.queue_free()

	return block_count

func simulate_and_evaluate_drop(
	tetrimino: Tetrimino
) -> int:
	# get the state of the grid before the drop & potential line clear
	var initial_grid_cells = grid_container.grid_cells.duplicate(true)
	var lines_cleared = 0

	# ensure that the tetrimino is in bounds before we move anything
	tetrimino.force_in_bounds()
	# drop one grid cell at a time until we *would* have to lock the tetrimino
	while tetrimino.can_move_down():
		tetrimino.global_position.y += grid_container.BLOCK_SIZE.y
	# fill the grid cells with the "locked" "ghost" tetrimino
	simulate_tetrimino_lock(tetrimino)

	# check if it's possible to clear any lines
	if has_full_lines():
		for y in range(Grid.GRID_HEIGHT - 1, -1, -1):
			var row = grid_container.grid_cells[y]
			# if every cell in the row has a Block ID, then increment the number
			# of possible line clears by 1
			if row.all(func(elem): return elem != null):
				lines_cleared += 1

	# calulate the score
	"""
	this is how the score is calculated:
		1. get the number of blocks currently on the grid (i.e. the block count 
		after the tetrimino was dropped, but before the line clearing).
		2. get the number of blocks deleted from a line clear 
		(lines cleared * the number of blocks in a row).
		3. subtract 2 from 1. this will return the current number of blocks in 
		the grid after dropping the tetrimino AND line clearing.

	essentially, the score corresponds to the number of blocks in the grid 
	after simulation. the lower the better!
	"""
	var block_count = get_block_count()
	var deleted_block_count = lines_cleared * Grid.GRID_WIDTH
	var score = block_count - deleted_block_count
	# make sure to reset the grid cells so that the ghost tetrimino is deleted
	grid_container.grid_cells = initial_grid_cells
	return score

func get_block_count() -> int:
	var block_count = 0
	for y in range(Grid.GRID_HEIGHT - 1, -1, -1):
		var row = grid_container.grid_cells[y]
		block_count += row.reduce(
			func(count, cell): return count + 1 if cell != null else count,
			0
		)
	return block_count

func has_full_lines() -> bool:
	for y in range(Grid.GRID_HEIGHT - 1, -1, -1):
		# if there's any cell where it is full of blocks, then return true
		var row = grid_container.grid_cells[y]
		if row.all(func(cell): return cell != null):
			return true
	return false

func simulate_tetrimino_lock(
	tetrimino: Tetrimino
) -> void:
	# determine the pixel coordinates of each block
	var block_coordinates: Array
	for block in tetrimino.get_blocks().get_children():
		var block_pos = block.global_position
		block_coordinates.append(block_pos)

	# convert them to grid coordinates
	block_coordinates = block_coordinates.map(Grid.pixel_to_grid)

	# for each block coordinate, fill the grid cell with a random integer
	for coord in block_coordinates:
		var row_index = clampi(floori(coord.y), 0, Grid.GRID_HEIGHT)
		var col_index = clampi(floori(coord.x), 0, Grid.GRID_WIDTH)
		grid_container.grid_cells[row_index][col_index] = randi()

func is_correct_solution_piece(t_shape: String) -> bool:
	# Compare t_shape with the solution's first element.
	var sol = solution.solution_list[0]
	return t_shape == sol["shape"]
