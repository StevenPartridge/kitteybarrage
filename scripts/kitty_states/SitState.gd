class_name SitState
extends State

var reverse := false
var start_paused := false

func name() -> Global.StateName:
	return Global.StateName.SIT

func _init(_reverse := false, _start_paused := false) -> void:
	reverse = _reverse
	start_paused = _start_paused

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "SitState requires a Kitty entity — FSM must be a child of Kitty")
	entity.velocity = Vector2.ZERO
	entity.anim.play_once("Sit", entity.facing_direction, reverse, start_paused)

func tick(_delta: float) -> State:
	return null

func _exit_state() -> void:
	entity.anim.cancel()
