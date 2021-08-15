extends Node

var window
var ctrl_pressed = false

func _ready() -> void:
	if OS.has_feature("JavaScript"):
		window = JavaScript.get_interface("window")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.scancode == KEY_CONTROL:
				ctrl_pressed = event.pressed
		elif event.pressed:
			if event.scancode == KEY_R and ctrl_pressed:
				reload_page()
			elif event.scancode in [KEY_F5, KEY_REFRESH]:
				reload_page()


func reload_page() -> void:
	if window == null:
		return
	window.location.reload()
