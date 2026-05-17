extends Node
class_name StateAnimator

signal animation_finished

# Play a one-shot animation and call on_done when it completes.
# Owns the signal connection — callers never touch animation_finished directly for transitions.
func play_transition(state_name: String, direction: Global.Direction, on_done: Callable, reverse: bool = false) -> void:
	pass

func play_loop(state_name: String, direction: Global.Direction, speed: float = 1.0) -> void:
	pass

func play_once(state_name: String, direction: Global.Direction, reverse: bool = false, start_paused: bool = false, start_frame: int = -1, stop_at_frame: int = -1, speed: float = 1.0) -> void:
	pass

func play_pose(state_name: String, direction: Global.Direction) -> void:
	pass

func hold_frame(state_name: String, direction: Global.Direction, frame: int) -> void:
	pass

func cancel() -> void:
	pass

func pause() -> void:
	pass

func get_frame_count(state_name: String, direction: Global.Direction) -> int:
	return 0

func get_playback_progress() -> float:
	return 0.0

func change_direction_while_playing(new_direction: int) -> void:
	pass

func set_modulate(color: Color) -> void:
	pass
