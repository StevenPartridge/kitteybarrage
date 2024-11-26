class_name WalkState
extends State

@export var is_sitting: bool = false

var is_standing_up: bool = false

func name():
	return "WalkState"

func _on_standup_finished():
	is_standing_up = false
	entity.play_animation("Walk", entity.facing_direction)

func _enter_state():
	if entity:
		print(entity.state_machine.previous_state)
		if entity.state_machine.previous_state == "SitState":
			is_standing_up = true
		if is_standing_up:
			entity.play_animation_once("Sit", entity.facing_direction, true) # start_from_end = true
			# Connect the animation_finished signal to transition to WalkState
			entity.animation_player.disconnect("animation_finished", _on_standup_finished)  # Avoid duplicates
			entity.animation_player.connect("animation_finished", _on_standup_finished)
	else:
		push_error("Entity reference is null in WalkState")

func _physics_process(delta):
	if entity:
		if entity.input_handler.is_moving() && !is_standing_up:
			entity.velocity = entity.input_handler.input_vector * entity.speed
			entity.move_and_slide()
			entity.facing_direction = entity.input_handler.get_facing_direction()
			# Update animation if direction changed
			#entity.play_animation("Walk", entity.facing_direction)
		else:
			entity.velocity = Vector2.ZERO
	else:
		push_error("Entity reference is null in WalkState")

func _exit_state():
	# Any cleanup if necessary
	pass
