class_name FiniteStateMachine
extends Node

@export var state: State

var current_state: String

func _ready():
	change_state(state)

func change_state(new_state: State):
	# Safely exit and free the current state if it exists

	
	if new_state:
		if current_state and (current_state == new_state.name()):
			return
		if state and not state.is_queued_for_deletion():
			state._exit_state()
			state.queue_free()
		state = null  # Clear the reference to the old state
		state = new_state
	if state:
		print("State ", state.name(), " and new_state ",  new_state.name())
		current_state = new_state.name()
		state.entity = get_parent()
		add_child(state)
		state._enter_state()
	else:
		push_error("Failed to change state: new_state is null.")
	
func _physics_process(delta):
	if state is State:
		state._physics_process(delta)
