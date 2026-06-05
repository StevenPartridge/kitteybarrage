extends Node
class_name StateAnimator

@warning_ignore("unused_signal")
signal animation_finished

# Play a one-shot animation and call on_done when it completes.
# Owns the signal connection — callers never touch animation_finished directly for transitions.
func play_transition(_state_name: String, _direction: Global.Direction, _on_done: Callable, _reverse: bool = false) -> void:
	pass

func play_loop(_state_name: String, _direction: Global.Direction, _speed: float = 1.0) -> void:
	pass

func play_once(_state_name: String, _direction: Global.Direction, _reverse: bool = false, _start_paused: bool = false, _start_frame: int = -1, _stop_at_frame: int = -1, _speed: float = 1.0) -> void:
	pass

func play_pose(_state_name: String, _direction: Global.Direction) -> void:
	pass

func hold_frame(_state_name: String, _direction: Global.Direction, _frame: int) -> void:
	pass

func cancel() -> void:
	pass

func pause() -> void:
	pass

func get_frame_count(_state_name: String, _direction: Global.Direction) -> int:
	return 0

func get_playback_progress() -> float:
	return 0.0

func change_direction_while_playing(_new_direction: Global.Direction) -> void:
	pass

func set_modulate(_color: Color) -> void:
	pass

func set_marking(_texture: Texture2D) -> void:
	pass

func clear_marking() -> void:
	pass
