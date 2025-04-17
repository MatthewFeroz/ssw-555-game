class_name TetriminoSlot
extends CenterContainer
const TETRIMINO_SCENE_PATH = "res://scenes/mini_game_1/tetrimino.tscn"
var tetrimino_scene := preload(TETRIMINO_SCENE_PATH)    # assign in the inspector
@export_enum("O","I","T","L","J","S","Z") var shape_name: String = "O"
@export_enum("0°", "90°", "180°", "270°") var rotation_angle: int = 0

# internal refs
@onready var panel: PanelContainer = $Panel
@onready var viewport: SubViewport = $Panel/SubViewportContainer/SubViewport
@onready var preview_root: Node2D = $Panel/SubViewportContainer/SubViewport/TetriminoPreview

var _is_selected : bool = false

func _ready():
	_update_style()
	_refresh_preview()

func _refresh_preview() -> void:
	# instantiate the tetrimino manager
	if tetrimino_scene:
		var tetrimino_manager = tetrimino_scene.instantiate()
		tetrimino_manager.t_shape = shape_name
		tetrimino_manager.block_size = 32.0
		tetrimino_manager.rotation_index = rotation_angle
		preview_root.add_child(tetrimino_manager)
		# center the preview node inside the panel
		var tetrimino = tetrimino_manager.get_tetrimino() as Tetrimino
		var bbox = tetrimino.get_bbox()
		# find the shape's true geometric center offset
		var center_offset = Vector2(
			(bbox.x + bbox.y) * 0.5,
			(bbox.w + bbox.z) * 0.5
		)
		# position the tetrimino so that its center is at the viewport's center
		tetrimino.position = viewport.size * 0.5 - center_offset

# Called by the selector to highlight/un‐highlight
func set_selected(selected: bool)->void:
	_is_selected = selected
	_update_style()

func _update_style():
	# build a fresh StyleBoxFlat each time:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color.MISTY_ROSE if _is_selected else Color.BLACK
	sb.border_color = Color.DEEP_PINK if _is_selected else Color.GREEN
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	# override the default “panel” style for this Panel
	panel.add_theme_stylebox_override("panel", sb)
