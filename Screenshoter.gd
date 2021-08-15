extends Node

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_down"):
		# start screen capture
		var img = get_viewport().get_texture().get_data()
		# save to a file
		img.flip_y()
		img.save_png("res://screenshots/" + str(OS.get_unix_time()) + ".png")
