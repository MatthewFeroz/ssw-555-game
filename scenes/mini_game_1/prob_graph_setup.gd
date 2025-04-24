extends Control

@export var graph_width : int = 600
@export var graph_height : int = 300
@export var rotation_range : float = 360  # The range for the x-axis (rotation, 0-360 degrees)
@export var step_size : float = 0.1  # Step size for probability (0-1)

var gridlines : Line2D

func _ready():
	# Create the gridlines
	gridlines = Line2D.new()
	add_child(gridlines)
	gridlines.default_color = Color(0.5, 0.5, 0.5, 0.5)  # Light gray for gridlines
	
	# Set up gridlines
	draw_gridlines()

func draw_gridlines():
	# Number of horizontal lines based on the step size (from 0 to 1)
	var num_lines = int(graph_height * step_size)
	
	# Draw horizontal gridlines (y-axis - probability)
	for i in range(num_lines + 1):  # +1 to include the last gridline
		var y = i * (graph_height / num_lines)  # Y position of the gridline
		gridlines.add_point(Vector2(0, y))
		gridlines.add_point(Vector2(graph_width, y))
