class_name FiniteStateMachine
extends Node

@export var state: State

@export var current_state: String
@export var previous_state: String
@export var wait_for_animation: bool = true

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
		previous_state = current_state
		current_state = new_state.name()
		state.entity = get_parent()
		state._enter_state()
		# Only add the state to the scene tree if it's not already a child
		if not state.get_parent():
			add_child(state)
	else:
		pass
		#push_error("Failed to change state: new_state is null.")
	
func _physics_process(delta):
	if state is State:
		state._physics_process(delta)
