class_name TetriminoSlot
extends CenterContainer

const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"

@export var slot_index: int = 0
@export var puzzle_num: int = 1 # start w puzzle_1.tres, then puzzle_2.tres after round 1 ends and round 2 begins

var tetrimino_scene := preload(TETRIMINO_SCENE_PATH)
var puzzle_data: PuzzleSolution
var shape_name := "O" # fallback shape
var rotation_angle := 0
var saved_probabilities := []

@onready var panel: PanelContainer = $Panel
@onready var viewport: SubViewport = $Panel/SubViewportContainer/SubViewport
@onready var preview_root: Node2D = $Panel/SubViewportContainer/SubViewport/TetriminoPreview

var _is_selected: bool = false

signal select(shape_name, rotation_angle, slot_index)
signal probs_updated(slot, new_probs)
signal rotation_changed(slot, new_rotation)

func _ready():
	_update_style()
	_refresh_preview()

# Modified to accept an optional state parameter
func _refresh_preview(state: Dictionary = {}):
	if preview_root:
		var tm = get_tetrimino_manager()
		if tm:
			# Save the current state before removing if not provided
			if state.is_empty() and tm.probabilities.size() > 0:
				saved_probabilities = tm.probabilities.duplicate()
				rotation_angle = (tm.rotation_index * 90) % 360
			
			# Disconnect signals before removing
			if tm.get_tetrimino().rotated.is_connected(_on_rotated):
				tm.get_tetrimino().disconnect("rotated", _on_rotated)
			if tm.probabilities_changed.is_connected(_on_probs_changed):
				tm.disconnect("probabilities_changed", _on_probs_changed)
				
			tm.name = "DeletedTetriminoManager"
			tm.queue_free()
			await get_tree().process_frame # Wait a frame for proper cleanup

	# Now create the new tetrimino manager
	if tetrimino_scene and not preview_root.has_node("TetriminoManager"):
		var tetrimino_manager = tetrimino_scene.instantiate()
		tetrimino_manager.t_shape = shape_name
		tetrimino_manager.block_size = 32.0
		
		# Use the rotation we already have stored
		tetrimino_manager.rotation_index = (rotation_angle / 90) % 4
		
		preview_root.add_child(tetrimino_manager)
		
		# Connect signals first
		tetrimino_manager.probabilities_changed.connect(_on_probs_changed)
		tetrimino_manager.get_tetrimino().rotated.connect(_on_rotated)
		
		# Apply saved probabilities if available
		var tetrimino = tetrimino_manager.get_tetrimino()
		
		# First center the tetrimino in the viewport
		var bbox = tetrimino.get_bbox()
		var center_offset = Vector2(
			(bbox.x + bbox.y) * 0.5,
			(bbox.w + bbox.z) * 0.5
		)
		tetrimino.position = viewport.size * 0.5 - center_offset
		
		# Apply supplied state if any
		if not state.is_empty():
			if state.has("rotation_angle"):
				rotation_angle = state["rotation_angle"]
				tetrimino_manager.rotation_index = (rotation_angle / 90) % 4
			
			if state.has("probabilities") and state["probabilities"].size() > 0:
				saved_probabilities = state["probabilities"].duplicate()
				# The probabilities need to be applied to the tetrimino's internal state
				if tetrimino and tetrimino._probabilities.size() == saved_probabilities.size():
					tetrimino._probabilities = saved_probabilities.duplicate()
					tetrimino.probs_changed.emit(saved_probabilities)
			
			if state.has("in_superposition") and state["in_superposition"]:
				tetrimino_manager.toggle_superposition(true)
		else:
			# Apply our saved probabilities if available
			if saved_probabilities.size() > 0 and tetrimino and tetrimino._probabilities.size() == saved_probabilities.size():
				tetrimino._probabilities = saved_probabilities.duplicate()
				tetrimino.probs_changed.emit(saved_probabilities)
		
		# Apply superposition state based on selection
		if _is_selected:
			tetrimino_manager.toggle_superposition(true)

func _on_rotated(rot_index: int) -> void:
	rotation_angle = rot_index * 90
	rotation_changed.emit(self, rotation_angle)

func _on_probs_changed(probs: Array) -> void:
	saved_probabilities = probs.duplicate()
	probs_updated.emit(self, probs)

func set_selected(selected: bool, emit: bool = true) -> void:
	if _is_selected == selected:
		return # No change, avoid extra logic

	_is_selected = selected
	
	_update_style()
	if preview_root:
		var tm = get_tetrimino_manager()
		if tm:
			tm.toggle_superposition(_is_selected)
	
	if emit:
		emit_signal("select", shape_name, rotation_angle, self)

func _update_style():
	var sb = StyleBoxFlat.new()
	if _is_selected:
		sb.bg_color = Color.MISTY_ROSE
		sb.border_color = Color.DEEP_PINK
	else:
		sb.bg_color = Color.BLACK
		sb.border_color = Color.GREEN

	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	
func get_tetrimino_manager() -> TetriminoManager:
	return preview_root.get_node_or_null("TetriminoManager") as TetriminoManager
	
# Will be called when resetting between puzzles
func reset_state() -> void:
	rotation_angle = 0
	saved_probabilities.clear()
	_is_selected = false
	
	# Clear any existing tetrimino manager
	if preview_root:
		var tm = get_tetrimino_manager()
		if tm:
			if tm.get_tetrimino().rotated.is_connected(_on_rotated):
				tm.get_tetrimino().disconnect("rotated", _on_rotated)
			if tm.probabilities_changed.is_connected(_on_probs_changed):
				tm.disconnect("probabilities_changed", _on_probs_changed)
			tm.name = "DeletedTetriminoManager"
			tm.queue_free()
	
	_update_style()
	_refresh_preview()
