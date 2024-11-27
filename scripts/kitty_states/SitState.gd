class_name SitState
extends State

var start_at_end := false  # Start the Sit animation at the end frame
var start_paused := false  # Start the Sit animation paused

func name():
	return "SitState"

func _init(_start_at_end := false, _start_paused := false):
	start_at_end = _start_at_end
	start_paused = _start_paused

func _enter_state():
	if entity:
		entity.velocity = Vector2.ZERO
		entity.play_animation_once("Sit", entity.facing_direction, start_at_end)
		# Connect the animation_finished signal to transition to WalkState
		
		listen_for_animation_end(_on_animation_finished)

		if start_paused:
			entity.pause()
	else:
		push_error("Entity reference is null in SitState")

func _physics_process(_delta):
	pass

func _exit_state():
	# Disconnect the signal to avoid interference
	if entity:
		if entity.animation_player.is_connected("animation_finished", _on_animation_finished):
			entity.animation_player.disconnect("animation_finished", _on_animation_finished)

# Handle the transition to WalkState after animation finishes
func _on_animation_finished():
	if entity:
		#entity.state_machine.change_state(WalkState.new())
		disconnect_from_animation_end(_on_animation_finished)
		pass
