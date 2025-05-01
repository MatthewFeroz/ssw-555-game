class_name TetriminoSlot
extends CenterContainer

const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"


@export var slot_index: int = 0
@export var puzzle_num: int = 1 # start w puzzle_1.tres, then puzzle_2.tres after round 1 ends and round 2 begins

var tetrimino_scene := preload(TETRIMINO_SCENE_PATH)
var puzzle_data: PuzzleSolution
var shape_name := "O" # fallback shape
var rotation_angle := 0

@onready var panel: PanelContainer = $Panel
@onready var viewport: SubViewport = $Panel/SubViewportContainer/SubViewport
@onready var preview_root: Node2D = $Panel/SubViewportContainer/SubViewport/TetriminoPreview

var _is_selected: bool = false

# signals
signal select(shape_name, rotation_angle, slot_index)
signal probs_updated(slot: Node, new_probs: Array)

func _ready():
	_update_style()
	_refresh_preview()


func _refresh_preview():
	var props = {}
	if preview_root:
		var tm = get_tetrimino_manager()
		if tm:
			props = {
				"in_superposition": tm.in_superposition,
				"probabilities": tm.probabilities,
				"t_shape": shape_name,
				"block_size": 32.0,
				"rotation_index": (rotation_angle / 90) % 4
			}
			tm.name = "DeletedTetriminoManager"
			# tm.get_tetrimino().disconnect("rotated", _on_rotated)
			tm.disconnect("probabilities_changed", _on_probs_changed)
			tm.queue_free()

	if tetrimino_scene:
		var tetrimino_manager = tetrimino_scene.instantiate()
		tetrimino_manager.name = "TetriminoManager"
		tetrimino_manager.in_superposition = props["in_superposition"] if props else false
		tetrimino_manager.probabilities = props["probabilities"] if props else []
		tetrimino_manager.t_shape = props["t_shape"] if props else shape_name
		tetrimino_manager.block_size = props["block_size"] if props else 32.0
		tetrimino_manager.rotation_index = props["rotation_index"] if props else (rotation_angle / 90) % 4
		tetrimino_manager.connect("probabilities_changed", _on_probs_changed)
		preview_root.add_child(tetrimino_manager)
		_recenter_tetrimino()

		# make sure to connect the rotated signal so that it automatically 
		# recenters the tetrimino after rotation.
		# tetrimino_manager.get_tetrimino().rotated.connect(_on_rotated)

		if props.has("in_superposition") and props["in_superposition"]:
			tetrimino_manager.toggle_superposition(true)

func _on_probs_changed(probs: Array) -> void:
	probs_updated.emit(self, probs)

func _recenter_tetrimino() -> void:
	if preview_root:
		var tm = get_tetrimino_manager()
		if not tm:
			return

		var tetrimino = tm.get_tetrimino()
		var bbox = tetrimino.get_bbox()
		var left = bbox.x - tetrimino.global_position.x
		var right = bbox.y - tetrimino.global_position.x
		var top = bbox.z - tetrimino.global_position.y
		var bottom = bbox.w - tetrimino.global_position.y
		var center_offset = Vector2(
			(left + right) * 0.5,
			(top + bottom) * 0.5
		)
		tetrimino.position = viewport.size * 0.5 - center_offset
		if _is_selected:
			tm.toggle_superposition(true)


func set_selected(selected: bool, emit: bool = true) -> void:
	if _is_selected == selected:
		return # No change, avoid extra logic

	_is_selected = selected
	
	_update_style()
	_refresh_preview()
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
	
	
# will load next puzzle at the end of round
func end_round() -> void:
	puzzle_num += 1
	_refresh_preview()
