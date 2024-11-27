class_name InputHandler
extends Node

# Signal emitted when there's a change in input direction
# signal direction_changed(new_direction: Vector2)

# The current input vector
var input_vector: Vector2 = Vector2.ZERO

var current_direction: Global.Direction = Global.Direction.SOUTH

func _process(_delta):
	var previous_input = input_vector
	input_vector = get_input_vector()

	if input_vector != previous_input:
		emit_signal("direction_changed", input_vector)

func get_input_vector() -> Vector2:
	var dir = Vector2.ZERO
	dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	return dir.normalized()

func get_facing_direction() -> Global.Direction:
	if input_vector == Vector2.ZERO:
		return current_direction  # No movement input
	var angle = input_vector.angle()
	var eight_directions = [
		Global.Direction.EAST,
		Global.Direction.SOUTHEAST,
		Global.Direction.SOUTH,
		Global.Direction.SOUTHWEST,
		Global.Direction.WEST,
		Global.Direction.NORTHWEST,
		Global.Direction.NORTH,
		Global.Direction.NORTHEAST
	]
	var index = int(round(angle / (PI / 4))) % 8
	current_direction = eight_directions[index]
	return eight_directions[index]

func is_moving() -> bool:
	return input_vector != Vector2.ZERO
