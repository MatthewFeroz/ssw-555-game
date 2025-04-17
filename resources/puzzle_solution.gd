extends Resource
class_name PuzzleSolution

# NOTE: Each element in the array is a dictionary. There are three keys in the 
# dictionary: the Tetrimino shape ("shape"), its rotation ("rotation"), and its 
# spawn position ("spawn_pos").
@export var solution_list: Array = []
@export var puzzle_name: String = ""
