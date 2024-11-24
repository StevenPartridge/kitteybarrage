extends State
class_name WalkState

func _enter_state():
	if entity:
		entity.play_animation("Walk", entity.facing_direction)
	else:
		push_error("Entity reference is null.")

func _physics_process(delta):
	if entity:
		if not entity.is_moving:
			emit_signal("state_finished", SitState.new(true))
		else:
			# Continue moving towards target
			entity.move_towards_target(delta)
	else:
		push_error("Entity reference is null.")
