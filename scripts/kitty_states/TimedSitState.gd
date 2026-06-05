extends State
class_name TimedSitState

var _next_state: State
var _hold_duration: float
var _elapsed := 0.0
var _sit_done := false

func _init(next_state: State, hold_duration: float = 0.12) -> void:
	_next_state = next_state
	_hold_duration = hold_duration

func name() -> Global.StateName:
	return Global.StateName.SIT

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "TimedSitState requires a Kitty entity — FSM must be a child of Kitty")
	_elapsed = 0.0
	_sit_done = false
	entity.velocity = Vector2.ZERO
	if entity.has_method("activate_claimed_surface_rendering"):
		entity.call("activate_claimed_surface_rendering")
	entity.anim.play_transition("Sit", entity.facing_direction, _on_sit_done)

func _on_sit_done() -> void:
	_sit_done = true

func tick(delta: float) -> State:
	if not _sit_done:
		return null
	_elapsed += delta
	if _elapsed >= _hold_duration:
		return _next_state if _next_state != null else SitState.new(true, true)
	return null

func _exit_state() -> void:
	entity.velocity = Vector2.ZERO
	entity.anim.cancel()
