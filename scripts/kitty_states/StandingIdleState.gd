class_name StandingIdleState
extends State

var _stand_ready_seconds: float = 60.0
var _rest_pose_seconds: float = 300.0
var _elapsed := 0.0

func _init(stand_ready_seconds: float = 60.0, rest_pose_seconds: float = 300.0) -> void:
	_stand_ready_seconds = maxf(0.0, stand_ready_seconds)
	_rest_pose_seconds = maxf(0.0, rest_pose_seconds)

func name() -> Global.StateName:
	return Global.StateName.STAND_IDLE

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "StandingIdleState requires a Kitty entity — FSM must be a child of Kitty")
	_elapsed = 0.0
	entity.velocity = Vector2.ZERO
	entity.clear_target()
	entity.anim.hold_frame("Walk", entity.facing_direction, 0)

func tick(delta: float) -> State:
	_elapsed += delta
	if _elapsed < _stand_ready_seconds:
		return null
	if entity.has_method("build_manual_rest_sit_state"):
		return entity.call("build_manual_rest_sit_state", _rest_pose_seconds) as State
	return SitState.new()

func _exit_state() -> void:
	entity.velocity = Vector2.ZERO
	entity.anim.cancel()
