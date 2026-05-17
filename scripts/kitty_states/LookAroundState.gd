extends State
class_name LookAroundState

const CENTER_FRAME: int = 3

# Override values — sentinel (-1 / -1.0) means "read from entity.personality"
var _next_state: State
var _loop: bool = false
var _ov_direction: int = -1
var _ov_speed: float = -1.0
var _ov_pause_right: float = -1.0
var _ov_pause_left: float = -1.0
var _ov_pause_center: float = -1.0
var _ov_repetitions: int = -1

# Runtime state
var _plan: Array = []
var _phase: int = 0
var _pause_timer: float = 0.0
var _reps_remaining: int = 1

func _init(next_state: State = null, loop: bool = false, direction: int = -1, speed: float = -1.0, pause_right: float = -1.0, pause_left: float = -1.0, pause_center: float = -1.0, repetitions: int = -1) -> void:
	_next_state = next_state if next_state else SitState.new(true, true)
	_loop = loop
	_ov_direction = direction
	_ov_speed = speed
	_ov_pause_right = pause_right
	_ov_pause_left = pause_left
	_ov_pause_center = pause_center
	_ov_repetitions = repetitions

func name() -> Global.StateName:
	return Global.StateName.LOOK_AROUND

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "LookAroundState requires a Kitty entity — FSM must be a child of Kitty")
	var kp := entity.personality as KittyPersonality
	var direction: int      = _ov_direction    if _ov_direction    >= 0   else (kp.look_around_direction   if kp else Global.LookDirection.BOTH)
	var speed: float        = _ov_speed        if _ov_speed        >= 0.0 else (kp.look_around_speed       if kp else 1.0)
	var pause_right: float  = _ov_pause_right  if _ov_pause_right  >= 0.0 else (kp.look_around_pause_right  if kp else 0.0)
	var pause_left: float   = _ov_pause_left   if _ov_pause_left   >= 0.0 else (kp.look_around_pause_left   if kp else 0.0)
	var pause_center: float = _ov_pause_center if _ov_pause_center >= 0.0 else (kp.look_around_pause_center if kp else 0.0)
	var reps: int           = _ov_repetitions  if _ov_repetitions  >= 0   else (kp.look_around_repetitions  if kp else 1)

	_reps_remaining = max(reps, 1)
	_phase = 0
	_pause_timer = 0.0
	entity.velocity = Vector2.ZERO
	_plan = _build_plan(direction, speed, pause_right, pause_left, pause_center)
	_execute_phase()

func _build_plan(direction: int, speed: float, pause_right: float, pause_left: float, pause_center: float) -> Array:
	var plan: Array = []
	match direction:
		Global.LookDirection.BOTH:
			plan.append({type="play",  reverse=false, start_frame=CENTER_FRAME, stop_frame=-1,             speed=speed})
			if pause_right  > 0.0: plan.append({type="pause", duration=pause_right})
			plan.append({type="play",  reverse=true,  start_frame=-1,           stop_frame=-1,             speed=speed})
			if pause_left   > 0.0: plan.append({type="pause", duration=pause_left})
			plan.append({type="play",  reverse=false, start_frame=-1,           stop_frame=CENTER_FRAME-1, speed=speed})
			if pause_center > 0.0: plan.append({type="pause", duration=pause_center})
		Global.LookDirection.RIGHT_ONLY:
			plan.append({type="play",  reverse=false, start_frame=CENTER_FRAME, stop_frame=-1,             speed=speed})
			if pause_right  > 0.0: plan.append({type="pause", duration=pause_right})
			plan.append({type="play",  reverse=true,  start_frame=-1,           stop_frame=CENTER_FRAME-1, speed=speed})
			if pause_center > 0.0: plan.append({type="pause", duration=pause_center})
		Global.LookDirection.LEFT_ONLY:
			plan.append({type="play",  reverse=true,  start_frame=CENTER_FRAME, stop_frame=-1,             speed=speed})
			if pause_left   > 0.0: plan.append({type="pause", duration=pause_left})
			plan.append({type="play",  reverse=false, start_frame=-1,           stop_frame=CENTER_FRAME-1, speed=speed})
			if pause_center > 0.0: plan.append({type="pause", duration=pause_center})
	return plan

func _execute_phase() -> void:
	if _phase >= _plan.size():
		return
	var step: Dictionary = _plan[_phase]
	if step.type == "pause":
		_pause_timer = step.duration
	else:
		entity.anim.play_once("LookAround", entity.facing_direction,
			step.reverse, false, step.start_frame, step.stop_frame, step.speed)
		entity.anim.animation_finished.connect(_on_play_done, CONNECT_ONE_SHOT)

func _on_play_done() -> void:
	_advance()

func _advance() -> void:
	_phase += 1
	if _phase < _plan.size():
		_execute_phase()
		return
	if _reps_remaining > 1:
		_reps_remaining -= 1
		_phase = 0
		_execute_phase()
	elif _loop:
		_phase = 0
		_execute_phase()

func tick(delta: float) -> State:
	if _phase >= _plan.size():
		return _next_state
	var step: Dictionary = _plan[_phase]
	if step.type == "pause":
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_advance()
	return null

func _exit_state() -> void:
	entity.anim.cancel()
