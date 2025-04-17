extends Resource
class_name PuzzleResource

# NOTE: Each array corresponds to a row in the grid. Each row is a dictionary 
# where the keys are the grid position of the block ("pos") and its color 
# ("color").
@export var starting_blocks: Array = []
@export var puzzle_name: String = ""
