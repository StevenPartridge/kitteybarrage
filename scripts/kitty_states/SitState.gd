class_name SitState
extends State

var reverse := false
var start_paused := false
var rest_duration := -1.0
var _elapsed := 0.0
var _next_state_factory: Callable

func name() -> Global.StateName:
	return Global.StateName.SIT

func _init(
	_reverse := false,
	_start_paused := false,
	_rest_duration := -1.0,
	next_state_factory: Callable = Callable()
) -> void:
	reverse = _reverse
	start_paused = _start_paused
	rest_duration = _rest_duration
	_next_state_factory = next_state_factory

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "SitState requires a Kitty entity — FSM must be a child of Kitty")
	_elapsed = 0.0
	entity.velocity = Vector2.ZERO
	if entity is Character:
		(entity as Character).activate_claimed_surface_rendering()
	entity.anim.play_once("Sit", entity.facing_direction, reverse, start_paused)

func tick(delta: float) -> State:
	if rest_duration < 0.0 or not _next_state_factory.is_valid():
		return null
	_elapsed += delta
	if _elapsed >= rest_duration:
		return _next_state_factory.call() as State
	return null

func _exit_state() -> void:
	if entity is Character:
		(entity as Character).release_hotspot_from_rest_state()
	else:
		entity.release_hotspot()
	entity.anim.cancel()
