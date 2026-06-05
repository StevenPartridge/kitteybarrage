extends State
class_name LookTrackState

const HALF_RANGE := PI / 2.0

var _get_target: Callable
var _num_frames: int = 7

func _init(get_target: Callable) -> void:
	_get_target = get_target

func name() -> Global.StateName:
	return Global.StateName.LOOK_TRACK

func _enter_state(_from: Global.StateName) -> void:
	entity.velocity = Vector2.ZERO
	_num_frames = entity.anim.get_frame_count("LookAround", entity.facing_direction)
	_update(_get_target.call())

func tick(_delta: float) -> State:
	_update(_get_target.call())
	return null

func _update(target_pos: Vector2) -> void:
	var to_target: Vector2 = target_pos - entity.position
	if to_target.length_squared() < 25.0:
		return

	var target_angle := to_target.angle()

	# Step facing direction toward target up to twice per frame
	# (handles the case where target is nearly directly behind)
	for _i in 2:
		var facing_rel := _wrap(target_angle - Global.direction_to_angle(entity.facing_direction))
		if abs(facing_rel) <= HALF_RANGE:
			break
		var current := int(entity.facing_direction)
		var target_dir := int(Global.direction_from_vector(to_target))
		var diff := (target_dir - current + 8) % 8
		entity.facing_direction = ((current + 1) % 8 if diff <= 4 else (current + 7) % 8) as Global.Direction
		_num_frames = entity.anim.get_frame_count("LookAround", entity.facing_direction)

	var rel := clampf(
		_wrap(target_angle - Global.direction_to_angle(entity.facing_direction)),
		-HALF_RANGE,
		HALF_RANGE
	)

	var t := (rel + HALF_RANGE) / (HALF_RANGE * 2.0)
	var frame := clampi(int(round(t * float(_num_frames - 1))), 0, _num_frames - 1)

	# West-side sprites run LookAround frames in the opposite order to the angle formula.
	match int(entity.facing_direction):
		Global.Direction.WEST, Global.Direction.NORTHWEST, Global.Direction.SOUTHWEST, Global.Direction.SOUTH:
			frame = (_num_frames - 1) - frame

	entity.anim.hold_frame("LookAround", entity.facing_direction, frame)

func _wrap(angle: float) -> float:
	while angle > PI:
		angle -= TAU
	while angle <= -PI:
		angle += TAU
	return angle

func _exit_state() -> void:
	entity.anim.cancel()
