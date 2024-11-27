class_name StandUpState
extends State

var start_at_end := false  # Start the Sit animation at the end frame

func name():
	return "StandUpState"

func _init(_start_at_end := false):
	start_at_end = _start_at_end

func _enter_state():
	if entity:
		entity.velocity = Vector2.ZERO
		entity.play_animation_once("Sit", entity.facing_direction, !start_at_end)
		# Connect the animation_finished signal to transition to WalkState
		listen_for_animation_end(_on_animation_finished)
	else:
		push_error("Entity reference is null in StandUpState")

func _physics_process(delta):
	pass

func _exit_state():
	# Disconnect the signal to avoid interference
	if entity:
		if entity.animation_player.is_connected("animation_finished", _on_animation_finished):
			entity.animation_player.disconnect("animation_finished", _on_animation_finished)

# Handle the transition to WalkState after animation finishes
func _on_animation_finished():
	if entity:
		entity.state_machine.change_state(WalkState.new())
