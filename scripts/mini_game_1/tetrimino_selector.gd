extends Control

# how far apart to float the popups
const POPUP_DISTANCE := 120

@export var slot_1: TetriminoSlot
@export var slot_2: TetriminoSlot
@export var slot_3: TetriminoSlot
@onready var slots := $HBoxContainer.get_children()  # should be exactly 3 TetriminoSlot nodes
var current_index: int = 0
var tetriminos = []

func _ready():
	if not slots.is_empty():
		_refresh_slots()

func _refresh_slots():
	for i in range(slots.size()):
		var tetrimino_manager = slots[i].tetrimino_scene.instantiate()
		tetrimino_manager.t_shape = slots[i].shape_name
		tetrimino_manager.block_size = 32.0
		tetrimino_manager.rotation_index = slots[i].rotation_angle
		if tetriminos.size() < slots.size():
			tetriminos.append(tetrimino_manager)
		slots[i].set_selected(i == current_index)

func set_tetrimino_slot(
	slot_num: int,
	t_shape: String
) -> void:
	var tetrimino_manager = slots[slot_num].tetrimino_scene.instantiate()
	tetrimino_manager.t_shape = t_shape
	tetrimino_manager.block_size = 32.0
	tetrimino_manager.rotation_index = 0
	slots[slot_num].shape_name = t_shape
	slots[slot_num].rotation_angle = 0

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
			KEY_ENTER:
				_confirm_choice()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# click‐to‐select
		for i in slots.size():
			var rect = slots[i].get_global_rect()
			if rect.has_point(event.position):
				current_index = i
				_refresh_slots()
				return

func _confirm_choice():
	# grab the PackedScene from the selected slot
	var chosen_scene : PackedScene = slots[current_index].tetrimino_scene
	_show_rotation_popups(chosen_scene)

func _show_rotation_popups(packed: PackedScene):
	# clear old popups if any
	for child in get_children():
		if child is PopupPanel:
			child.queue_free()

	# 4 directions: 0=N, 90=E, 180=S, 270=W
	for angle in [0, 90, 180, 270]:
		var popup = PopupPanel.new()
		# style it so you can see it:
		popup.size = Vector2(128,128)
		add_child(popup)

		# position around the selected slot
		var dir = Vector2.UP.rotated(deg_to_rad(angle))
		var base_pos = slots[current_index].global_position
		show_popup_at(popup, base_pos + dir * POPUP_DISTANCE)

		# now instance the preview
		var pv = Node2D.new()
		popup.add_child(pv)
		pv.position = popup.size * 0.5   # center in popup

		var tetrimino_manager = packed.instantiate() 
		tetrimino_manager.t_shape = tetriminos[current_index].t_shape
		tetrimino_manager.block_size = tetriminos[current_index].block_size
		tetrimino_manager.rotation_index = (angle / 90) % 4
		var tetrimino = tetrimino_manager.get_tetrimino()
		pv.add_child(tetrimino_manager)

		#popup.popup_()  # show it

func show_popup_at(
	popup_rect,
	global_pos: Vector2
) -> void:
	var popup_size = popup_rect.get_size()
	popup_rect.popup(Rect2i(global_pos, popup_size))
