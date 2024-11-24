extends Node
class_name State

#signal state_finished

var entity  # Reference to the Kitty node

func get_state_name():
	return get_class()

func _init():
	pass

func _enter_state():
	pass

func _exit_state():
	pass
