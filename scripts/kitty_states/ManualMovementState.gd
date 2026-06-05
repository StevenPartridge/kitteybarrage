class_name ManualMovementState
extends State

const STANDING_IDLE_STATE := preload("res://scripts/kitty_states/StandingIdleState.gd")

var _input_handler: InputHandler
var _current_anim := ""
var _walk_speed: float = 70.0
var _run_multiplier: float = 1.55
var _acceleration: float = 650.0
var _deceleration: float = 900.0
var _stand_ready_seconds: float = 60.0
var _rest_pose_seconds: float = 300.0

func _init(
	input_handler: InputHandler,
	walk_speed: float = 70.0,
	run_multiplier: float = 1.55,
	acceleration: float = 650.0,
	deceleration: float = 900.0,
	stand_ready_seconds: float = 60.0,
	rest_pose_seconds: float = 300.0
) -> void:
	configure(
		input_handler,
		walk_speed,
		run_multiplier,
		acceleration,
		deceleration,
		stand_ready_seconds,
		rest_pose_seconds
	)

func configure(
	input_handler: InputHandler,
	walk_speed: float,
	run_multiplier: float,
	acceleration: float,
	deceleration: float,
	stand_ready_seconds: float,
	rest_pose_seconds: float
) -> void:
	_input_handler = input_handler
	_walk_speed = maxf(0.0, walk_speed)
	_run_multiplier = maxf(0.0, run_multiplier)
	_acceleration = maxf(0.0, acceleration)
	_deceleration = maxf(0.0, deceleration)
	_stand_ready_seconds = maxf(0.0, stand_ready_seconds)
	_rest_pose_seconds = maxf(0.0, rest_pose_seconds)

func name() -> Global.StateName:
	return Global.StateName.MANUAL_MOVE

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "ManualMovementState requires a Kitty entity — FSM must be a child of Kitty")
	entity.clear_target()
	_current_anim = ""
	if _input_handler != null and _input_handler.is_moving():
		_update_facing(_input_handler.input_vector)
	_play_for_input()

func tick(delta: float) -> State:
	if _input_handler == null or not _input_handler.is_moving():
		entity.velocity = entity.velocity.move_toward(Vector2.ZERO, _deceleration * delta)
		if entity.velocity.length_squared() > 1.0:
			return null
		entity.velocity = Vector2.ZERO
		return STANDING_IDLE_STATE.new(_stand_ready_seconds, _rest_pose_seconds)

	var input_vector := _input_handler.input_vector
	entity.velocity = entity.velocity.move_toward(
		input_vector * _manual_speed(),
		_acceleration * delta
	)
	_update_facing(input_vector)
	_play_for_input()
	return null

func _manual_speed() -> float:
	if _input_handler != null and _input_handler.is_running():
		return _walk_speed * _run_multiplier
	return _walk_speed

func _update_facing(input_vector: Vector2) -> void:
	if input_vector.length_squared() < 0.01:
		return
	var next_direction := Global.direction_from_vector(input_vector)
	if entity.facing_direction == next_direction:
		return
	entity.facing_direction = next_direction
	entity.anim.change_direction_while_playing(next_direction)

func _play_for_input() -> void:
	if _input_handler == null or not _input_handler.is_moving():
		return
	var anim_name := "Run" if _input_handler.is_running() else "Walk"
	if _current_anim == anim_name:
		entity.anim.change_direction_while_playing(entity.facing_direction)
		return
	_current_anim = anim_name
	entity.anim.play_loop(anim_name, entity.facing_direction)

func _exit_state() -> void:
	entity.velocity = Vector2.ZERO
	entity.anim.pause()
