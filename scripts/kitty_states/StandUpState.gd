class_name StandUpState
extends State

var _next_state: State
var _done: bool = false

func _init(next_state: State) -> void:
	_next_state = next_state

func name() -> Global.StateName:
	return Global.StateName.STANDUP

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "StandUpState requires a Kitty entity — FSM must be a child of Kitty")
	_done = false
	_rotation_frame_count = 0
	entity.anim.play_transition("Sit", entity.facing_direction, _on_standup_finished, true)

func _on_standup_finished() -> void:
	_done = true

func tick(_delta: float) -> State:
	_tick_rotation()
	if _done:
		return _next_state
	if entity.navigation_target != null and entity.navigation_target.is_valid():
		var progress: float = entity.anim.get_playback_progress()
		var direction: Vector2 = (entity.navigation_target.get_position() - entity.position).normalized()
		entity.velocity = direction * entity.speed * pow(progress, 2)
	return null

func _exit_state() -> void:
	entity.anim.cancel()
	entity.velocity = Vector2.ZERO
