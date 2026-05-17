class_name InputHandler
extends Node

var input_vector: Vector2 = Vector2.ZERO
var current_direction: Global.Direction = Global.Direction.SOUTH

var _source: InputSource

func _init(source: InputSource) -> void:
	_source = source

func _process(_delta) -> void:
	input_vector = _source.get_input_vector()

func get_facing_direction() -> Global.Direction:
	if input_vector == Vector2.ZERO:
		return current_direction
	current_direction = Global.direction_from_vector(input_vector)
	return current_direction

func is_moving() -> bool:
	return input_vector != Vector2.ZERO

func is_running() -> bool:
	return _source.is_running()
