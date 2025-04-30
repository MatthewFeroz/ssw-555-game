extends Control

const CARD_SCENE = preload("res://MiniGame/EntangledCards/Card.tscn")

@onready var card_grid: GridContainer = $MainLayout/CardGrid
@onready var clue_panel: Control = $MainLayout/RightVBox/CluePanel
@onready var countdown_panel: Control = $CountdownPanel
@onready var quiz_panel: Control = $MainLayout/RightVBox/QuizPanel
@onready var feedback_panel: Control = $MainLayout/RightVBox/FeedbackPanel
@onready var finish_panel: Control = $MainLayout/RightVBox/FinishPanel
@onready var score_label: Label = $MainLayout/RightVBox/ScoreLabel
@onready var instruction_panel: Control = $InstructionPanel

var round: int = 1
var score: int = 0
var cards_data: Array = []

var red_clue: Array = []
var green_clue: Array = []
var blue_clue: Array = []

var last_flipped_color := ""
var last_flipped_index := -1

func _ready() -> void:
	randomize()
	start_instruction_phase()

func start_instruction_phase() -> void:
	instruction_panel.visible = true
	instruction_panel.set_instruction_text("🧠 Memorize these clues!\n\nEach color group has 3 cards.\nIf you know one, you can guess the others!")
	card_grid.visible = false
	score_label.visible = false
	clue_panel.visible = false
	quiz_panel.visible = false

	await get_tree().create_timer(7.0).timeout
	instruction_panel.visible = false
	start_countdown_phase()

func start_countdown_phase() -> void:
	countdown_panel.visible = true
	await countdown_panel.start_countdown()
	countdown_panel.visible = false
	start_memorization_phase()

func start_memorization_phase() -> void:
	score_label.visible = true
	clue_panel.visible = true
	card_grid.visible = true
	quiz_panel.visible = false

	start_round()

	await get_tree().create_timer(12.0).timeout
	clue_panel.visible = false
	hide_all_card_values()
	start_quiz()

func start_round() -> void:
	score_label.text = "Score: %d" % score

	red_clue = [randi() % 2, randi() % 2, randi() % 2]
	green_clue = [randi() % 2, randi() % 2, randi() % 2]
	blue_clue = [randi() % 2, randi() % 2, randi() % 2]

	spawn_cards()

	clue_panel.set_clue_text(
		"❤️ = %d ➔ 👑 = %d ➔ 💲 = %d" % red_clue,
		"💚 = %d ➔ 👑 = %d ➔ 💲 = %d" % green_clue,
		"💙 = %d ➔ 👑 = %d ➔ 💲 = %d" % blue_clue,
		round
	)
	clue_panel.show_clue(10.0)

func spawn_cards() -> void:
	queue_free_children(card_grid)
	cards_data.clear()

	var symbol_names = ["Heart", "King", "Money"]
	var designs_by_color = {
		"Red": [
			load("res://assets/Cards/Heart_Red.png"),
			load("res://assets/Cards/King_Red.png"),
			load("res://assets/Cards/Money_Red.png")
		],
		"Green": [
			load("res://assets/Cards/Heart_Green.png"),
			load("res://assets/Cards/King_Green.png"),
			load("res://assets/Cards/Money_Green.png")
		],
		"Blue": [
			load("res://assets/Cards/Heart_Blue.png"),
			load("res://assets/Cards/King_Blue.png"),
			load("res://assets/Cards/Money_Blue.png")
		]
	}

	for i in range(3):
		cards_data.append({ "color": "Red", "value": red_clue[i], "texture": get_scaled_texture(designs_by_color["Red"][i], Vector2(150, 200)), "symbol": symbol_names[i] })
		cards_data.append({ "color": "Green", "value": green_clue[i], "texture": get_scaled_texture(designs_by_color["Green"][i], Vector2(150, 200)), "symbol": symbol_names[i] })
		cards_data.append({ "color": "Blue", "value": blue_clue[i], "texture": get_scaled_texture(designs_by_color["Blue"][i], Vector2(150, 200)), "symbol": symbol_names[i] })

	cards_data.shuffle()

	for data in cards_data:
		var card_instance = CARD_SCENE.instantiate()
		card_instance.set_card_data(data["color"], data["value"], data["texture"], data["symbol"])
		card_grid.add_child(card_instance)

func hide_all_card_values() -> void:
	for card in card_grid.get_children():
		card.hide_value()

func start_quiz():
	var flipped_card = card_grid.get_children().pick_random()
	flipped_card._on_button_pressed()

	var color = flipped_card.get_color()
	var symbol_name = flipped_card.get_symbol()

	last_flipped_color = color
	var symbol_index := 2  # from earlier logic
	if symbol_name == "Heart":
		symbol_index = 0
	elif symbol_name == "King":
		symbol_index = 1
	elif symbol_name == "Money":
		symbol_index = 2

	var clue_group: Array
	if color == "Red":
		clue_group = red_clue
	elif color == "Green":
		clue_group = green_clue
	else:
		clue_group = blue_clue

	last_flipped_index = symbol_index

	var symbol_emoji = ["❤️", "👑", "💲"][symbol_index]

	var remaining_symbols := []
	var remaining_values := []

	for i in range(3):
		if i != symbol_index:
			remaining_symbols.append(["❤️", "👑", "💲"][i])
			remaining_values.append(clue_group[i])

	var question = "If %s %s is %d, what are %s and %s (in order)?" % [
		color, symbol_emoji, clue_group[symbol_index],
		remaining_symbols[0], remaining_symbols[1]
	]

	var correct_value = "%d,%d" % remaining_values

	var option_pool = ["0,0", "1,1", "0,1", "1,0"]
	option_pool.shuffle()
	if !option_pool.has(correct_value):
		option_pool[0] = correct_value
	option_pool.shuffle()

	var correct_key = ""
	var keys = ["A", "B", "C", "D"]
	var options := {}

	for i in range(4):
		options[keys[i]] = option_pool[i]
		if option_pool[i] == correct_value:
			correct_key = keys[i]

	quiz_panel.visible = true
	quiz_panel.set_question(question, options, correct_key)
	quiz_panel.answer_selected.connect(on_answer_selected)

func on_answer_selected(is_correct: bool) -> void:
	quiz_panel.visible = false
	feedback_panel.show_result(is_correct)
	feedback_panel.next_pressed.connect(on_next_pressed)

	if is_correct:
		score += 10

	for card in card_grid.get_children():
		if card.get_color() == last_flipped_color:
			card._on_button_pressed()  # Simulate flip
	score_label.text = "Score: %d" % score

func on_next_pressed() -> void:
	feedback_panel.visible = false
	round += 1

	if round > 3:
		finish_panel.set_score(score)
		finish_panel.visible = true
	else:
		start_countdown_phase()

func get_scaled_texture(original: Texture2D, size: Vector2) -> Texture2D:
	var image := original.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)

func queue_free_children(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()
