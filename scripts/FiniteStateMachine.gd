class_name FiniteStateMachine
extends Node

@export var state: State
var _current_state: Global.StateName = Global.StateName.SIT

func _ready():
	if state:
		change_state(state)

func change_state(new_state: State) -> void:
	var from: Global.StateName = _current_state
	if new_state:
		if state != null and _current_state == new_state.name():
			return
		if state and not state.is_queued_for_deletion():
			state._exit_state()
			state.queue_free()
		state = null
		state = new_state
	if state and new_state:
		_current_state = new_state.name()
		state.entity = get_parent() as CharacterBase
		state._enter_state(from)
		if not state.get_parent():
			add_child(state)
		state.set_physics_process(false)
	else:
		push_error("Failed to change state: new_state is null.")

func _physics_process(delta):
	if state is State:
		var next = state.tick(delta)
		if next:
			change_state(next)

func current_state_name() -> Global.StateName:
	return _current_state
