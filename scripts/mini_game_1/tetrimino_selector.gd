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
		
		##### test begin 
func _refresh_slots():
	if slots.size() == 3 and tetriminos_data.size() == 3:
		for i in range(slots.size()):
			var piece_data = tetriminos_data[i]
			slots[i].shape_name = piece_data["shape"]
			slots[i].rotation_angle = piece_data["rotation"]
			slots[i].set_selected(i == current_index)
			slots[i]._refresh_preview()
			
			
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				if current_index > 0:
					current_index -= 1
					_refresh_slots()
			KEY_RIGHT:
				var num_visible_slots = slots.reduce(func(accum, elem): return accum + 1 if elem.visible else accum, 0)
				var only_slot = num_visible_slots == 1
				if only_slot:
					return
				if current_index < slots.size() - 1:
					current_index += 1
					while not slots[current_index].visible and current_index < slots.size() - 1:
						current_index += 1
					_refresh_slots()
	#		KEY_ENTER:
	#			_confirm_choice()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# click‐to‐select
		for i in slots.size():
			var rect = slots[i].get_global_rect()
			if rect.has_point(event.position) and slots[i].visible:
				current_index = i
				_refresh_slots()
				return
