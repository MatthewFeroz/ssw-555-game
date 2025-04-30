extends Control

@onready var countdown_label = $CountdownLabel

func start_countdown():
	visible = true
	for i in range(3, 0, -1):
		countdown_label.text = "Game starts in... " + str(i)
		await get_tree().create_timer(1.0).timeout
	visible = false
