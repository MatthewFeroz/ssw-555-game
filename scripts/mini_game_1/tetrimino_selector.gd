extends Control

@export var puzzle_file: PuzzleSolution

@export var slot_1: TetriminoSlot
@export var slot_2: TetriminoSlot
@export var slot_3: TetriminoSlot
@onready var slots := $HBoxContainer.get_children() # should be exactly 3 TetriminoSlot nodes
var current_index: int = -1
var tetriminos_data = []

# Store the state of each tetrimino slot
var slot_states = {
	# Key is the slot index, value is a dictionary with:
	# - rotation_angle: The current rotation angle
	# - probabilities: Array of probabilities
	# - in_superposition: Whether the tetrimino is in superposition
}

func _ready():
	# Initialize slot states with default values
	for i in range(3):
		slot_states[i] = {
			"rotation_angle": 0,
			"probabilities": [],
			"in_superposition": false
		}
	
	# Check if puzzle file is provided
	if puzzle_file:
		tetriminos_data = puzzle_file.solution_pieces.duplicate(true) # Deep copy to avoid modifying the source
		print("Loaded tetriminos data: ", tetriminos_data)
		_refresh_slots() # Refresh slots with data from the puzzle
		
func _refresh_slots():
	if slots.size() == 3 and tetriminos_data.size() == 3:
		for i in range(slots.size()):
			var piece_data = tetriminos_data[i]
			
			# Only update the rotation angle if we haven't modified it yet
			if not slot_states[i]["probabilities"].size() > 0:
				slot_states[i]["rotation_angle"] = piece_data["rotation"]
			
			slots[i].shape_name = piece_data["shape"]
			slots[i].rotation_angle = slot_states[i]["rotation_angle"]
			slots[i].set_selected(i == current_index)
			
			# Store and connect to signals before refreshing to avoid losing connections
			if not slots[i].is_connected("probs_updated", _on_slot_probs_updated):
				slots[i].connect("probs_updated", _on_slot_probs_updated)
			if not slots[i].is_connected("rotation_changed", _on_slot_rotation_changed):
				slots[i].connect("rotation_changed", _on_slot_rotation_changed)
			
			# Pass the saved state to the slot when refreshing
			slots[i]._refresh_preview(slot_states[i])

# Add this new method to reset all slots when moving to next puzzle
func reset_all_slots():
	for i in range(slot_states.size()):
		slot_states[i] = {
			"rotation_angle": 0,
			"probabilities": [],
			"in_superposition": false
		}
	current_index = -1
	_refresh_slots()

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
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# click-to-select
		for i in slots.size():
			var rect = slots[i].get_global_rect()
			if rect.has_point(event.position) and slots[i].visible:
				current_index = i
				_refresh_slots()
				return

# New callback functions to update our stored state
func _on_slot_probs_updated(slot: Node, new_probs: Array) -> void:
	# Find the index of the slot
	var index = slots.find(slot)
	if index != -1:
		slot_states[index]["probabilities"] = new_probs.duplicate()

func _on_slot_rotation_changed(slot: Node, new_rotation: int) -> void:
	# Find the index of the slot
	var index = slots.find(slot)
	if index != -1:
		slot_states[index]["rotation_angle"] = new_rotation
