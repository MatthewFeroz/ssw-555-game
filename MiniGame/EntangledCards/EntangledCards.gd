extends Control

const CARD_SCENE = preload("res://MiniGame/EntangledCards/Card.tscn")
@onready var card_grid = $CardGrid

func _ready():
	randomize()
	spawn_cards()

func spawn_cards():
	for child in card_grid.get_children():
		child.queue_free()

	var cards_data = []
	var designs_by_color = {
		"Red": [
			{"texture": load("res://assets/Cards/Heart_Red.png")},
			{"texture": load("res://assets/Cards/King_Red.png")},
			{"texture": load("res://assets/Cards/Money_Red.png")}
		],
		"Green": [
			{"texture": load("res://assets/Cards/Heart_Green.png")},
			{"texture": load("res://assets/Cards/King_Green.png")},
			{"texture": load("res://assets/Cards/Money_Green.png")}
		],
		"Blue": [
			{"texture": load("res://assets/Cards/Heart_Blue.png")},
			{"texture": load("res://assets/Cards/King_Blue.png")},
			{"texture": load("res://assets/Cards/Money_Blue.png")}
		]
	}

	for color in designs_by_color.keys():
		var rand_values = []
		for i in range(3):
			rand_values.append(randi() % 2)

		for i in range(3):
			var original_texture = designs_by_color[color][i]["texture"]
			var scaled_texture = get_scaled_texture(original_texture, Vector2(150, 200))
			cards_data.append({
				"color": color,
				"value": rand_values[i],
				"texture": scaled_texture
			})

	cards_data.shuffle()

	for data in cards_data:
		var card_instance = CARD_SCENE.instantiate()
		card_instance.set_card_data(data["color"], data["value"], data["texture"])
		card_grid.add_child(card_instance)

func get_scaled_texture(original: Texture2D, size: Vector2) -> Texture2D:
	var image := original.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)
