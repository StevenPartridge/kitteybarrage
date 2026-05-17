extends NavigationTarget
class_name NodeTarget

var _node: Node2D

func _init(node: Node2D) -> void:
	_node = node

func get_position() -> Vector2:
	return _node.global_position

func is_valid() -> bool:
	return is_instance_valid(_node) and _node.is_inside_tree()
