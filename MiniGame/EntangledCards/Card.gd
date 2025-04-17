extends TextureButton

signal card_flipped(card)

var card_color: String = ""
var card_value: int = 0
var is_flipped: bool = false
var original_texture: Texture2D

func _ready():
	connect("pressed", self._on_button_pressed)

func set_card_data(new_color: String, new_value: int, design_texture: Texture2D) -> void:
	card_color = new_color
	card_value = new_value
	original_texture = design_texture
	texture_normal = original_texture
	is_flipped = false

func _on_button_pressed():
	is_flipped = !is_flipped

	if is_flipped:
		var value_texture_path = "res://assets/Cards/Zero.png" if card_value == 0 else "res://assets/Cards/One.png"
		var value_texture = load(value_texture_path)
		texture_normal = get_scaled_texture(value_texture, Vector2(150, 200))
	else:
		texture_normal = original_texture

	emit_signal("card_flipped", self)

func get_color() -> String:
	return card_color

func get_scaled_texture(original: Texture2D, size: Vector2) -> Texture2D:
	var image := original.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)
