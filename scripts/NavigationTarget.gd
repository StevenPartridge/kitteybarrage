extends RefCounted
class_name NavigationTarget

func get_position() -> Vector2:
	assert(false, "NavigationTarget.get_position() must be overridden")
	return Vector2.ZERO

func is_valid() -> bool:
	assert(false, "NavigationTarget.is_valid() must be overridden")
	return false
