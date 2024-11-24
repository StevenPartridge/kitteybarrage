extends State
class_name IdleState

func _enter_state():
	owner.velocity = Vector2.ZERO
	owner.play_animation("Idle", owner.facing_direction)

func _physics_process(delta):
	var input_vector = owner.get_input_vector()
	if input_vector != Vector2.ZERO:
		# Transition to WalkState
		emit_signal("state_finished", WalkState.new())
	elif Input.is_action_just_pressed("action_sit"):
		emit_signal("state_finished", SitState.new())
