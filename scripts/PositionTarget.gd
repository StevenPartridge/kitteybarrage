extends NavigationTarget
class_name PositionTarget

var _position: Vector2

func _init(pos: Vector2) -> void:
	_position = pos

func get_position() -> Vector2:
	return _position

func is_valid() -> bool:
	return true
