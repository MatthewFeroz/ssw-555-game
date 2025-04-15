extends Node

@export_dir var puzzles_path: String = "res://resources/puzzles"
var puzzles: Dictionary = {}	# puzzle_name: key, PuzzleResource: value

func _ready() -> void:
	load_all_puzzles()

func load_all_puzzles() -> void:
	# here, we'll scan the puzzles folder for puzzle resources
	puzzles.clear()
	var dir = DirAccess.open(puzzles_path)
	if dir:
		# don't include any hidden files or "."/".."
		if dir.get_include_hidden():
			dir.set_include_hidden(false)
		if dir.get_include_navigational():
			dir.set_include_navigational(false)

		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":	# while there are files to scan...
			# load all puzzle resources
			if file_name.ends_with(".tres"):
				var res_path = puzzles_path + "/" + file_name
				var puzzle_res = load(res_path)
				if puzzle_res and puzzle_res is PuzzleResource:
					puzzles[puzzle_res.puzzle_name] = puzzle_res
			file_name = dir.get_next()
	else:
		print(DirAccess.get_open_error())
		push_error("Failed to open puzzles folder: " + puzzles_path)

func get_random_puzzle() -> PuzzleResource:
	if puzzles.size() > 0:
		var keys = puzzles.keys()
		var rand_key = keys[randi() % keys.size()]
		return puzzles[rand_key]

	return null

func get_puzzle_by_name(puzzle_name: String) -> PuzzleResource:
	return puzzles.get(puzzle_name)

func create_and_save_puzzle(
	puzzle_data: Array,
	puzzle_name: String,
	file_path: String
) -> Error:
	var puzzle = PuzzleResource.new()
	puzzle.starting_blocks = puzzle_data
	puzzle.puzzle_name = puzzle_name
	return ResourceSaver.save(puzzle, file_path)
