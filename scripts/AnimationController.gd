class_name AnimationController
extends StateAnimator

var _player: AnimatedSprite2D
var _current_state_name: String = ""
var _current_direction: Global.Direction = Global.Direction.SOUTH
var _is_loop: bool = false
var _is_reverse: bool = false
var _loop_restored_anim: String = ""
var _stop_at_frame: int = -1

const _MARKING_SHADER := "res://assets/shaders/MarkingOverlay.gdshader"

func setup(player: AnimatedSprite2D) -> void:
	_player = player
	var mat := ShaderMaterial.new()
	mat.shader = load(_MARKING_SHADER)
	mat.set_shader_parameter("marking_opacity", 0.0)
	_player.material = mat

func play_transition(state_name: String, direction: Global.Direction, on_done: Callable, reverse: bool = false) -> void:
	play_once(state_name, direction, reverse)
	animation_finished.connect(on_done, CONNECT_ONE_SHOT)

func play_loop(state_name: String, direction: Global.Direction, speed: float = 1.0) -> void:
	if _is_loop and _current_state_name == state_name and _current_direction == direction and _player.is_playing():
		return
	_cancel_silent()
	var anim_name := Global.get_full_animation_name(state_name, direction)
	if not _player.sprite_frames.has_animation(anim_name):
		push_error("Animation not found: " + anim_name)
		return
	_current_state_name = state_name
	_current_direction = direction
	_is_loop = true
	_is_reverse = false
	_player.speed_scale = speed
	_player.play(anim_name)

# reverse:        play backwards (last frame → first)
# start_paused:   play then immediately pause (show a held pose)
# start_frame:    begin playback at this frame index (-1 = default start)
# stop_at_frame:  pause and fire animation_finished when this frame is reached (-1 = play to end)
func play_once(state_name: String, direction: Global.Direction, reverse: bool = false, start_paused: bool = false, start_frame: int = -1, stop_at_frame: int = -1, speed: float = 1.0) -> void:
	_cancel_silent()
	var anim_name := Global.get_full_animation_name(state_name, direction)
	if not _player.sprite_frames.has_animation(anim_name):
		push_error("Animation not found: " + anim_name)
		return
	_current_state_name = state_name
	_current_direction = direction
	_is_loop = false
	_is_reverse = reverse
	if _player.sprite_frames.get_animation_loop(anim_name):
		_player.sprite_frames.set_animation_loop(anim_name, false)
		_loop_restored_anim = anim_name
	if stop_at_frame >= 0:
		_stop_at_frame = stop_at_frame
		_player.frame_changed.connect(_on_frame_changed)
	else:
		_player.animation_finished.connect(_on_animation_finished)
	_player.speed_scale = speed
	if reverse:
		_player.play_backwards(anim_name)
	else:
		_player.play(anim_name)
	if start_frame >= 0:
		_player.frame = start_frame
	if start_paused:
		_player.pause()

func cancel() -> void:
	_cancel_silent()

# Show the last frame of an animation as a static pose — no gate, no signal.
# Used by TurnState to update facing direction while holding a sitting/lying pose.
func play_pose(state_name: String, direction: Global.Direction) -> void:
	_cancel_silent()
	var anim_name := Global.get_full_animation_name(state_name, direction)
	if not _player.sprite_frames.has_animation(anim_name):
		push_error("Animation not found: " + anim_name)
		return
	_current_state_name = state_name
	_current_direction = direction
	_is_loop = false
	_is_reverse = true
	if _player.sprite_frames.get_animation_loop(anim_name):
		_player.sprite_frames.set_animation_loop(anim_name, false)
		_loop_restored_anim = anim_name
	_player.play_backwards(anim_name)
	_player.pause()

func pause() -> void:
	_player.pause()

func get_frame_count(state_name: String, direction: Global.Direction) -> int:
	var anim_name := Global.get_full_animation_name(state_name, direction)
	if not _player.sprite_frames.has_animation(anim_name):
		return 0
	return _player.sprite_frames.get_frame_count(anim_name)

# Hold a specific frame of an animation as a static pose — used by LookTrackState.
# Switches direction variant if needed without replaying from the start.
func hold_frame(state_name: String, direction: Global.Direction, frame: int) -> void:
	var anim_name := Global.get_full_animation_name(state_name, direction)
	if not _player.sprite_frames.has_animation(anim_name):
		push_error("Animation not found: " + anim_name)
		return
	if _player.animation != anim_name:
		_cancel_silent()
		_current_state_name = state_name
		_current_direction = direction
		_is_loop = false
		_is_reverse = false
		_player.play(anim_name)
		_player.pause()
	elif _player.is_playing():
		_player.pause()
	_player.frame = frame

func set_modulate(color: Color) -> void:
	if _player != null:
		_player.modulate = color

func set_marking(texture: Texture2D) -> void:
	var mat := _player.material as ShaderMaterial if _player != null else null
	if mat == null:
		return
	mat.set_shader_parameter("marking_texture", texture)
	mat.set_shader_parameter("marking_opacity", 1.0)

func clear_marking() -> void:
	var mat := _player.material as ShaderMaterial if _player != null else null
	if mat == null:
		return
	mat.set_shader_parameter("marking_opacity", 0.0)

func get_playback_progress() -> float:
	if _current_state_name.is_empty():
		return 0.0
	var total_frames: int = _player.sprite_frames.get_frame_count(_player.animation)
	if total_frames == 0:
		return 0.0
	var divisor := float(max(total_frames - 1, 1))
	var frame_f := float(_player.frame) + _player.frame_progress
	if _is_reverse:
		return 1.0 - frame_f / divisor
	return frame_f / divisor

func _cancel_silent() -> void:
	if not _loop_restored_anim.is_empty():
		if _player != null and _player.sprite_frames.has_animation(_loop_restored_anim):
			_player.sprite_frames.set_animation_loop(_loop_restored_anim, true)
		_loop_restored_anim = ""
	if _player != null:
		if _player.animation_finished.is_connected(_on_animation_finished):
			_player.animation_finished.disconnect(_on_animation_finished)
		if _player.frame_changed.is_connected(_on_frame_changed):
			_player.frame_changed.disconnect(_on_frame_changed)
	_stop_at_frame = -1
	_current_state_name = ""
	_current_direction = Global.Direction.SOUTH
	_is_loop = false
	_is_reverse = false
	if _player != null:
		_player.speed_scale = 1.0

# Swap to a new directional variant of the current animation at the same progress.
# Does NOT call _cancel_silent — preserves the state's animation_finished connection.
func change_direction_while_playing(new_direction: Global.Direction) -> void:
	if _current_state_name.is_empty() or _current_direction == new_direction:
		return
	var anim_name := Global.get_full_animation_name(_current_state_name, new_direction)
	if not _player.sprite_frames.has_animation(anim_name):
		push_error("Animation not found: " + anim_name)
		return
	if _player.animation_finished.is_connected(_on_animation_finished):
		_player.animation_finished.disconnect(_on_animation_finished)
	if _player.frame_changed.is_connected(_on_frame_changed):
		_player.frame_changed.disconnect(_on_frame_changed)
	if not _loop_restored_anim.is_empty():
		if _player.sprite_frames.has_animation(_loop_restored_anim):
			_player.sprite_frames.set_animation_loop(_loop_restored_anim, true)
		_loop_restored_anim = ""
	_current_direction = new_direction
	if _is_loop:
		_player.play(anim_name)
	else:
		if _player.sprite_frames.get_animation_loop(anim_name):
			_player.sprite_frames.set_animation_loop(anim_name, false)
			_loop_restored_anim = anim_name
		if _stop_at_frame >= 0:
			_player.frame_changed.connect(_on_frame_changed)
		else:
			_player.animation_finished.connect(_on_animation_finished)
		var progress := get_playback_progress()
		# from_end=false avoids the deferred set_frame_and_progress(0,0) that from_end=true triggers
		_player.play(anim_name, -1.0 if _is_reverse else 1.0, false)
		var new_total: int = _player.sprite_frames.get_frame_count(anim_name)
		if new_total > 1:
			var frame_f: float
			if _is_reverse:
				frame_f = (1.0 - progress) * float(new_total - 1)
			else:
				frame_f = progress * float(new_total - 1)
			_player.set_frame_and_progress(clampi(int(frame_f), 0, new_total - 1), frame_f - float(int(frame_f)))

func _on_frame_changed() -> void:
	if _player.frame == _stop_at_frame:
		_on_animation_finished()

func _on_animation_finished() -> void:
	_cancel_silent()
	_player.pause()
	animation_finished.emit()
