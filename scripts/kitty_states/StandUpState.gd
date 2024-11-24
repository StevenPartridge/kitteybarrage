extends State
class_name StandUpState

func _enter_state():
	if entity:
		# Play the 'Sit' animation in reverse to simulate standing up
		entity.play_animation("Sit", entity.facing_direction)
		var animated_sprite = entity.get_node("AnimatedSprite2D")
		animated_sprite.playback_speed = -1  # Play in reverse
		animated_sprite.frame = animated_sprite.frames.get_frame_count(animated_sprite.animation) - 1
		animated_sprite.connect("animation_finished", self, "_on_animation_finished")
	else:
		push_error("Entity reference is null.")

func _exit_state():
	var animated_sprite = entity.get_node("AnimatedSprite2D")
	animated_sprite.disconnect("animation_finished", self, "_on_animation_finished")

func _on_animation_finished():
	emit_signal("state_finished", WalkState.new())

func _physics_process(_delta):
	pass  # No additional physics processing needed
