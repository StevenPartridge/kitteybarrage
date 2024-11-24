class_name FiniteStateMachine
extends Node

@export var state: State

func _ready():
	change_state(state)

func change_state(new_state: State):
	
	if state is State:
		state._exit_state()
		state.queue_free()
	if new_state:
		state = new_state
	if state:
		
		state.entity = get_parent()
		add_child(state)
		state._enter_state()
	else:
		push_error("Failed to change state: new_state is null.")
	
func _physics_process(delta):
	if state is State:
		state._physics_process(delta)
