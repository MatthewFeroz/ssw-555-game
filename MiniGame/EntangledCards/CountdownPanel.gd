extends Control

@onready var countdown_label = $CountdownLabel
@onready var countdown_sound = $CountdownSound  # Ensure this node exists and is properly set up

func start_countdown():
	visible = true

	# Play sound once at the start
	if not countdown_sound.playing:
		countdown_sound.play()

	for i in range(3, 0, -1):
		countdown_label.text = "Game starts in... " + str(i)
		await get_tree().create_timer(0.6).timeout

	visible = false
