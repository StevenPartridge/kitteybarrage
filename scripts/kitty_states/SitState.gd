class_name SitState
extends State

var start_at_end := false

func _init(_start_at_end := false):
	start_at_end = _start_at_end

func _enter_state():
	if entity:
		entity.velocity = Vector2.ZERO
		entity.play_animation("Sit", entity.facing_direction, start_at_end)
	else:
		push_error("Entity reference is null.")

func _physics_process(_delta):
	if entity:
		# Wait for input or signal to start moving
		if entity.is_moving:
			emit_signal("state_finished", StandUpState.new())
	else:
		push_error("Entity reference is null.")
