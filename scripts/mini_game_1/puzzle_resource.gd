extends Resource
class_name PuzzleResource

# TODO (4/10/25): refactor so that puzzles can be chosen in the selector OR in code

# below are all the puzzles in their original form
# NOTE: Each array corresponds to a row in the grid.
var puzzle_1 = [
	[
		{ "pos": Vector2(0, Grid.GRID_HEIGHT - 1), "color": Color.ORANGE },
		{ "pos": Vector2(1, Grid.GRID_HEIGHT - 1), "color": Color.CYAN },
		{ "pos": Vector2(2, Grid.GRID_HEIGHT - 1), "color": Color.ORANGE },
		{ "pos": Vector2(4, Grid.GRID_HEIGHT - 1), "color": Color.BLUE },
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 1), "color": Color.RED },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 1), "color": Color.YELLOW },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 1), "color": Color.ORANGE },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 1), "color": Color.BLUE },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 1), "color": Color.CYAN }
	],
	[
		{ "pos": Vector2(0, Grid.GRID_HEIGHT - 2), "color": Color.ORANGE },
		{ "pos": Vector2(1, Grid.GRID_HEIGHT - 2), "color": Color.PURPLE },
		{ "pos": Vector2(2, Grid.GRID_HEIGHT - 2), "color": Color.LIME },
		{ "pos": Vector2(4, Grid.GRID_HEIGHT - 2), "color": Color.LIME },
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 2), "color": Color.RED },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 2), "color": Color.YELLOW },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 2), "color": Color.ORANGE },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 2), "color": Color.RED },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 2), "color": Color.YELLOW }
	],
	[
		{ "pos": Vector2(0, Grid.GRID_HEIGHT - 3), "color": Color.ORANGE },
		{ "pos": Vector2(1, Grid.GRID_HEIGHT - 3), "color": Color.LIME },
		{ "pos": Vector2(2, Grid.GRID_HEIGHT - 3), "color": Color.YELLOW },
		{ "pos": Vector2(4, Grid.GRID_HEIGHT - 3), "color": Color.BLUE },
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 3), "color": Color.ORANGE },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 3), "color": Color.ORANGE },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 3), "color": Color.BLUE },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 3), "color": Color.ORANGE },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 3), "color": Color.YELLOW }
	],
	[
		{ "pos": Vector2(0, Grid.GRID_HEIGHT - 4), "color": Color.YELLOW },
		{ "pos": Vector2(1, Grid.GRID_HEIGHT - 4), "color": Color.PURPLE },
		{ "pos": Vector2(2, Grid.GRID_HEIGHT - 4), "color": Color.CYAN },
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 4), "color": Color.PURPLE },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 4), "color": Color.YELLOW },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 4), "color": Color.PURPLE },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 4), "color": Color.BLUE },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 4), "color": Color.RED }
	],
	[
		{ "pos": Vector2(0, Grid.GRID_HEIGHT - 5), "color": Color.PURPLE },
		{ "pos": Vector2(1, Grid.GRID_HEIGHT - 5), "color": Color.RED },
		{ "pos": Vector2(2, Grid.GRID_HEIGHT - 5), "color": Color.PURPLE },
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 5), "color": Color.PURPLE },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 5), "color": Color.CYAN },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 5), "color": Color.CYAN },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 5), "color": Color.RED },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 5), "color": Color.LIME }
	],
	[
		{ "pos": Vector2(5, Grid.GRID_HEIGHT - 6), "color": Color.CYAN },
		{ "pos": Vector2(6, Grid.GRID_HEIGHT - 6), "color": Color.YELLOW },
		{ "pos": Vector2(7, Grid.GRID_HEIGHT - 6), "color": Color.LIME },
		{ "pos": Vector2(8, Grid.GRID_HEIGHT - 6), "color": Color.CYAN },
		{ "pos": Vector2(9, Grid.GRID_HEIGHT - 6), "color": Color.BLUE }
	]
]


@export var starting_blocks: Array = puzzle_1
