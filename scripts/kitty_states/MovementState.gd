class_name MovementState
extends State

var _state_name: Global.StateName
var _anim_name: String
var _speed_fn: Callable

const ARRIVAL_DISTANCE := 3.0

func _init(state_name: Global.StateName, anim_name: String, speed_fn: Callable) -> void:
	_state_name = state_name
	_anim_name = anim_name
	_speed_fn = speed_fn

func name() -> Global.StateName:
	return _state_name

static func walk() -> MovementState:
	return MovementState.new(Global.StateName.WALK, "Walk", func(_p: CharacterPersonality) -> float: return 1.0)

static func run() -> MovementState:
	return MovementState.new(Global.StateName.RUN, "Run", func(p: CharacterPersonality) -> float: return p.run_speed_multiplier)

static func sprint() -> MovementState:
	return MovementState.new(Global.StateName.SPRINT, "Sprint", func(p: CharacterPersonality) -> float: return p.sprint_speed_multiplier)

func _enter_state(_from: Global.StateName) -> void:
	assert(entity != null, "MovementState requires a Kitty entity — FSM must be a child of Kitty")
	_rotation_frame_count = 0
	entity.anim.play_loop(_anim_name, entity.facing_direction)

func tick(_delta: float) -> State:
	if entity.navigation_target != null and entity.navigation_target.is_valid():
		var target_pos: Vector2 = entity.navigation_target.get_position()
		if entity.global_position.distance_to(target_pos) <= ARRIVAL_DISTANCE:
			entity.clear_target()
			entity.velocity = Vector2.ZERO
			return entity.pop_arrival_state()
		var direction: Vector2
		if entity.nav_agent != null:
			entity.nav_agent.target_position = target_pos
			var next_pos: Vector2 = target_pos if entity.nav_agent.is_navigation_finished() else entity.nav_agent.get_next_path_position()
			direction = (next_pos - entity.global_position).normalized()
		else:
			direction = (target_pos - entity.position).normalized()
		entity.velocity = direction * entity.speed * _speed_fn.call(entity.personality)
		_tick_rotation()
		entity.anim.play_loop(_anim_name, entity.facing_direction)
	else:
		entity.velocity = Vector2.ZERO
		entity.anim.pause()
		return entity.pop_arrival_state()
	return null

func _exit_state() -> void:
	entity.velocity = Vector2.ZERO
	entity.anim.pause()
