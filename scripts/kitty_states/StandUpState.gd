class_name StandUpState
extends State

var start_at_end := false  # Start the Sit animation at the end frame
var start_paused := false # Starts paused, as if sitting
var state_finished := false
func name():
	return "StandUpState"

func _init(_start_at_end := false, _start_paused := false):
	#super()._init()
	start_at_end = _start_at_end
	start_paused = _start_paused

func _enter_state():
	if entity:
		entity.velocity = Vector2.ZERO
		entity.play_animation_once("Sit", entity.facing_direction, ! start_at_end)
		if start_paused:
			entity.pause()
	else:
		push_error("Entity reference is null in StandUpState")

func _physics_process(delta):
	pass

func _exit_state():
	# Any cleanup if necessary
	pass
