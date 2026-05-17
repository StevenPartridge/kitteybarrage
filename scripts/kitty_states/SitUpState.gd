extends State
class_name SitUpState

var _next_state: State
var _done: bool = false

func _init(next_state: State) -> void:
	_next_state = next_state

func name() -> Global.StateName:
	return Global.StateName.SITUP

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "SitUpState requires a Kitty entity — FSM must be a child of Kitty")
	_done = false
	_rotation_frame_count = 0
	entity.velocity = Vector2.ZERO
	entity.anim.play_transition("Lay", entity.facing_direction, _on_done, true)

func _on_done() -> void:
	_done = true

func tick(_delta: float) -> State:
	_tick_rotation()
	if _done:
		return _next_state
	return null

func _exit_state() -> void:
	entity.anim.cancel()
	entity.velocity = Vector2.ZERO
