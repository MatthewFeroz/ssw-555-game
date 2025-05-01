extends HBoxContainer

@onready var bar_label_map = [
	{
		"bar": $bar_and_label_1/prob_bar_1,
		"label": $bar_and_label_1/prob_label_1
	},
	{
		"bar": $bar_and_label_2/prob_bar_2,
		"label": $bar_and_label_2/prob_label_2
	},
	{
		"bar": $bar_and_label_3/prob_bar_3,
		"label": $bar_and_label_3/prob_label_3
	},
	{
		"bar": $bar_and_label_4/prob_bar_4,
		"label": $bar_and_label_4/prob_label_4
	}
]
@onready var default_slot = $/root/Node/TetriminoSelector/HBoxContainer/TetriminoSlot1

# constants for tetrimino shape data
const TETRIMINO_SHAPES_PATH = "res://resources/shapes/tetrimino_shapes.tres"
const TETRIMINO_DATA = preload(TETRIMINO_SHAPES_PATH)	# tetrimino_shape: key, shape_data: value

# constants for bar charts
const MAX_BAR_SIZE = Vector2(50.0, 300.0)

# member variables
var num_visible_probs = 0
var current_slot: Node = null

# built-in functions
func _ready() -> void:
	# wait until after the frame so that the default slot's tetrimino manager
	# is initialized
	await get_tree().process_frame
	# set the current slot to the default slot
	current_slot = default_slot
	var tm = current_slot.get_tetrimino_manager()
	var probs = tm.probabilities if tm else []
	_draw_bars(current_slot.shape_name, probs)

	# display the correct bar chart for the probabilities associated with the current slot
	current_slot.select.emit(current_slot.shape_name, 0, current_slot)

	# ensure that every slot has listener for updating the bar graphs
	for slot in get_tree().get_nodes_in_group("tetrimino_slots"):
		slot.connect("select", _on_slot_selected)
		slot.connect("probs_updated", _on_probs_updated)

# custom functions

# getter functions
func get_shape_color(shape_name: String) -> Color:
	return TETRIMINO_DATA["shapes"][shape_name]["color"]

# setter functions
func set_visibility(
	bar: ColorRect,
	label: Label,
	state: bool = true
) -> void:
	bar.visible = state
	label.visible = state

func set_bar_color(
	bar: ColorRect,
	new_color: Color,
) -> void:
	bar.color = new_color

func set_label_text(
	label: Label,
	new_text: String
) -> void:
	label.text = new_text

func set_bar_height(
	bar: ColorRect,
	height: float
) -> void:
	bar.custom_minimum_size = Vector2(MAX_BAR_SIZE.x, height)

# property modification functions
func toggle_visibility(
	bar: ColorRect,
	label: Label
) -> void:
	bar.visible = !bar.visible
	label.visible = !label.visible


# internal functions
func _on_slot_selected(shape_name: String, _rotation_angle: int, slot_index: Node) -> void:
	if current_slot == slot_index:
		# Deselect if already selected
		current_slot = null
		for i in range(bar_label_map.size()):
			var bar = bar_label_map[i]["bar"]
			var label = bar_label_map[i]["label"]
			set_bar_height(bar, 0)
			set_label_text(label, "0%")
	else:
		# Select new slot
		current_slot = slot_index
		var color = get_shape_color(shape_name)
		for i in range(bar_label_map.size()):
			var bar = bar_label_map[i]["bar"]
			var label = bar_label_map[i]["label"]
			set_bar_color(bar, color)

func _on_probs_updated(slot: Node, probs: Array) -> void:
	if slot != current_slot:
		return

	_draw_bars(slot.shape_name, probs)

func _draw_bars(shape_name: String, probs: Array) -> void:
	var color = get_shape_color(shape_name)
	for i in range(bar_label_map.size()):
		var bar = bar_label_map[i]["bar"]
		var label = bar_label_map[i]["label"]
		if i < probs.size():
			var percentage: int = roundi(probs[i] * 100)
			set_bar_height(bar, probs[i] * MAX_BAR_SIZE.y)
			set_bar_color(bar, color)
			set_label_text(label, "%d%%" % percentage)
			set_visibility(bar, label, true)
		else:
			set_bar_height(bar, 0)
			set_label_text(label, "0%")
			set_visibility(bar, label, false)
