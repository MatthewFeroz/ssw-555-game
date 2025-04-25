extends Control

@export var puzzle_file: PuzzleSolution

@export var slot_1: TetriminoSlot
@export var slot_2: TetriminoSlot
@export var slot_3: TetriminoSlot
@onready var slots := $HBoxContainer.get_children()  # should be exactly 3 TetriminoSlot nodes
var current_index: int = 0
var tetriminos = []
var tetriminos_data = []




func _ready():
	# Check if puzzle file is provided
	if puzzle_file:
		tetriminos_data = puzzle_file.solution_pieces  # Access the array from the file
		print(tetriminos_data)  # Print out the data to verify its structure
		_refresh_slots()  # Refresh slots with data from the puzzle
		
		
func _refresh_slots():
	if slots.size() == 3 and tetriminos_data.size() == 3:
		for i in range(slots.size()):
			# Get the tetrimino piece from the puzzle data (using the index i)
			var piece_data = tetriminos_data[i]  # piece_data is a dictionary (rotation, shape, position)
			
			# Set the shape, rotation, and position from the puzzle data to the corresponding slot
			slots[i].shape_name = piece_data["shape"]  # Set shape (e.g., "T", "L", etc.)
			slots[i].rotation_angle = piece_data["rotation"]  # Set rotation (angle in degrees)
			slots[i].set_selected(i == current_index)
			
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				if current_index > 0:
					current_index -= 1
					_refresh_slots()
			KEY_RIGHT:
				if current_index < slots.size() - 1:
					current_index += 1
					_refresh_slots()
	#		KEY_ENTER:
	#			_confirm_choice()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# click‐to‐select
		for i in slots.size():
			var rect = slots[i].get_global_rect()
			if rect.has_point(event.position):
				current_index = i
				_refresh_slots()
				return
