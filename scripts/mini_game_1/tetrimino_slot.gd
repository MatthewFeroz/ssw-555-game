class_name TetriminoSlot
extends CenterContainer

const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"


@export var slot_index: int = 0
@export var puzzle_num: int = 1 #start w puzzle_1.tres, then puzzle_2.tres after round 1 ends and round 2 begins

var tetrimino_scene := preload(TETRIMINO_SCENE_PATH)
var puzzle_data: PuzzleSolution
var shape_name := "O"  # fallback shape
var rotation_angle := 0

@onready var panel: PanelContainer = $Panel
@onready var viewport: SubViewport = $Panel/SubViewportContainer/SubViewport
@onready var preview_root: Node2D = $Panel/SubViewportContainer/SubViewport/TetriminoPreview

var _is_selected : bool = false


signal select(shape_name, rotation_angle, slot_index)

func _ready():
	_update_style()
	_refresh_preview()


func _refresh_preview():
	for child in preview_root.get_children():
		child.queue_free()

	if tetrimino_scene:
		var tetrimino_manager = tetrimino_scene.instantiate()
		tetrimino_manager.t_shape = shape_name
		tetrimino_manager.block_size = 32.0
		tetrimino_manager.rotation_index = (rotation_angle/90) % 4
		preview_root.add_child(tetrimino_manager)

		var tetrimino = tetrimino_manager.get_tetrimino()
		var bbox = tetrimino.get_bbox()
		var center_offset = Vector2(
			(bbox.x + bbox.y) * 0.5,
			(bbox.w + bbox.z) * 0.5
		)
		tetrimino.position = viewport.size * 0.5 - center_offset



func set_selected(selected: bool, emit: bool = true) -> void:
	if _is_selected == selected:
		return # No change, avoid extra logic

	_is_selected = selected
	
	_update_style()

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
	
	
# will load next puzzle at the end of round
func end_round() -> void:
	puzzle_num += 1
	_refresh_preview() 
