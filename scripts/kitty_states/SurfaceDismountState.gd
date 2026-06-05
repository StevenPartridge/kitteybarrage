extends State
class_name SurfaceDismountState

const DEFAULT_DURATION := 0.16

var _target_position: Vector2
var _next_state: State
var _duration: float
var _start_position := Vector2.ZERO
var _elapsed := 0.0
var _completed := false

func _init(target_position: Vector2, next_state: State, duration: float = DEFAULT_DURATION) -> void:
	_target_position = target_position
	_next_state = next_state
	_duration = duration

func name() -> Global.StateName:
	return Global.StateName.SURFACE_DISMOUNT

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "SurfaceDismountState requires a Kitty entity — FSM must be a child of Kitty")
	_completed = false
	_elapsed = 0.0
	_start_position = entity.global_position
	entity.velocity = Vector2.ZERO
	_face_toward(_target_position)
	entity.anim.play_loop("Walk", entity.facing_direction)

func tick(delta: float) -> State:
	if _target_position == Vector2.INF or _duration <= 0.0:
		return _finish()
	_elapsed += delta
	var t := clampf(_elapsed / _duration, 0.0, 1.0)
	entity.global_position = _start_position.lerp(_target_position, _smooth_step(t))
	if t >= 1.0:
		return _finish()
	return null

func _finish() -> State:
	_completed = true
	if entity.has_method("complete_surface_dismount"):
		entity.call("complete_surface_dismount", _target_position)
	else:
		if _target_position != Vector2.INF:
			entity.global_position = _target_position
	entity.velocity = Vector2.ZERO
	return _next_state if _next_state != null else SitState.new(true, true)

func _face_toward(target_position: Vector2) -> void:
	if target_position == Vector2.INF:
		return
	var delta := target_position - entity.global_position
	if delta.length_squared() < 4.0:
		return
	entity.facing_direction = Global.direction_from_vector(delta)

func _smooth_step(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func _exit_state() -> void:
	if not _completed and entity.has_method("complete_surface_dismount"):
		entity.call("complete_surface_dismount", _target_position)
	entity.velocity = Vector2.ZERO
	entity.anim.pause()
