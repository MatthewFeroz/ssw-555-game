extends Node2D

@export var tilemap: TileMap
@export var boundary_margin: int = 16 

var map_bounds: Rect2 

# Signal to notify when a lesson or mini-game is selected
signal location_selected(location_name)

func _ready():
	if tilemap:
		calculate_map_bounds()
	else:
		print("TileMap not assigned to map.gd")

	# Connect all interactive buttons on the map
	for button in get_tree().get_nodes_in_group("map_buttons"):
		button.pressed.connect(_on_location_selected.bind(button))

func calculate_map_bounds():
	var used_rect = tilemap.get_used_rect()
	var tile_size = tilemap.tile_set.tile_size
	var world_start = tilemap.map_to_local(used_rect.position)
	var world_end = tilemap.map_to_local(used_rect.end)

	map_bounds = Rect2(world_start, world_end - world_start)
	print("Map Bounds:", map_bounds)

func keep_inside_map(position: Vector2) -> Vector2:
	""" Ensure the player doesn't move outside the map boundaries """
	return position.clamp(map_bounds.position + Vector2(boundary_margin, boundary_margin),
					  map_bounds.end - Vector2(boundary_margin, boundary_margin))

# Function to handle selection of a lesson or mini-game
func _on_location_selected(button: Button):
	var location_name = button.name
	print("Selected location: " + location_name)
	location_selected.emit(location_name)
