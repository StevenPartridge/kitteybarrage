extends Node
class_name State

var entity: CharacterBase
var rotation_frames: int = 8
var _rotation_frame_count: int = 0

func name() -> Global.StateName:
	return Global.StateName.SIT

func _init():
	pass

func _enter_state(_from: Global.StateName) -> void:
	pass

func _exit_state() -> void:
	pass

func tick(_delta: float) -> State:
	return null

func _tick_rotation() -> void:
	if entity == null or entity.navigation_target == null or not entity.navigation_target.is_valid():
		return
	var to_target: Vector2 = entity.navigation_target.get_position() - entity.position
	if to_target.length() < 5.0:
		return
	var target_dir: int = int(Global.direction_from_vector(to_target))
	if int(entity.facing_direction) == target_dir:
		return
	_rotation_frame_count += 1
	if _rotation_frame_count < rotation_frames:
		return
	_rotation_frame_count = 0
	var current: int = int(entity.facing_direction)
	var diff: int = (target_dir - current + 8) % 8
	var new_dir := ((current + 1) % 8 if diff <= 4 else (current + 7) % 8) as Global.Direction
	entity.facing_direction = new_dir
	entity.anim.change_direction_while_playing(new_dir)
