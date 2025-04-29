class_name TetriminoSlot
extends CenterContainer

const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"
const PUZZLE_DATA_PATH = "res://resources/solutions/puzzle_" # ← update to your actual file path

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

signal select(shape_name, rotation_angle, slot_index)

func _ready():
	load_puzzle() # Load the current puzzle based on puzzle_num
	_update_style()
	_refresh_preview()

# loads correct puzzl3
func load_puzzle() -> void:
	var puzzle_file_path = PUZZLE_DATA_PATH + str(puzzle_num) + ".tres"
	print("Loading puzzle file: ", puzzle_file_path)

	var resource = ResourceLoader.load(puzzle_file_path)
	if resource and resource is PuzzleSolution:
		puzzle_data = resource
		print("Puzzle loaded successfully! Solution count: ", puzzle_data.solution_pieces.size())
	else:
		print("Error: Could not load puzzle file or file is not of type PuzzleSolution.")

func _refresh_preview() -> void:
	# Access the solutions array directly
	if puzzle_data and slot_index < puzzle_data.solution_pieces.size():
		var entry = puzzle_data.solution_pieces[slot_index]
		if entry.has("shape"):
			shape_name = entry["shape"]
		if entry.has("rotation"):
			rotation_angle = entry["rotation"]
	# Instantiate the tetrimino
	if tetrimino_scene:
		var tetrimino_manager = tetrimino_scene.instantiate()
		tetrimino_manager.t_shape = shape_name
		tetrimino_manager.block_size = 32.0
		tetrimino_manager.rotation_index = (rotation_angle / 90) % 4
		preview_root.add_child(tetrimino_manager)

		var tetrimino = tetrimino_manager.get_tetrimino()
		var bbox = tetrimino.get_bbox()
		var center_offset = Vector2(
			(bbox.x + bbox.y) * 0.5,
			(bbox.w + bbox.z) * 0.5
		)
		tetrimino.position = viewport.size * 0.5 - center_offset
		
		
func _on_button_pressed() -> void:
	set_selected(_is_selected)
	#toggle_superposition()

func set_selected(selected: bool, emit_signal: bool = true) -> void:
	_is_selected = selected
	#emit_signal("select", shape_name, rotation_angle, self)
	#select.emit(shape_name, rotation_angle)
	_update_style()
	if emit_signal:
		emit_signal("select", shape_name, rotation_angle, self)
	

func _update_style():
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.MISTY_ROSE if _is_selected else Color.BLACK
	sb.border_color = Color.DEEP_PINK if _is_selected else Color.GREEN
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)


# will load next puzzle at the end of round
func end_round() -> void:
	puzzle_num += 1
	load_puzzle()
	_refresh_preview()
