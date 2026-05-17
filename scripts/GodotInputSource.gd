class_name GodotInputSource
extends InputSource

func get_input_vector() -> Vector2:
	var dir := Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return dir.normalized()

func is_running() -> bool:
	return Input.is_action_pressed("run")
