class_name WalkState
extends State

@export var is_sitting: bool = false
var in_standup_animation: bool = false

func name():
	return Global.StateName.WALK

func _on_standup_finished():
	in_standup_animation = false
	entity.play_animation("Walk", entity.facing_direction)

func _enter_state():
	if entity:
		if entity.state_machine.previous_state == Global.StateName.SIT:
			in_standup_animation = true
		if in_standup_animation:
			entity.play_animation_once("Sit", entity.facing_direction, true)
			listen_for_animation_end(_on_standup_finished)
	else:
		push_error("Entity reference is null in WalkState")

func _physics_process(_delta):
	if entity:
		if entity.input_handler.is_moving():
			entity.velocity = entity.input_handler.input_vector * entity.speed
			entity.facing_direction = entity.input_handler.get_facing_direction()
			if not in_standup_animation:
				entity.move_and_slide()
				# Update animation if direction changed
				entity.play_animation("Walk", entity.facing_direction)
		else:
			entity.velocity = Vector2.ZERO
			# string includes "Walk"
			if entity.animation_player.animation.find("Walk") != -1:
				entity.pause()
	else:
		push_error("Entity reference is null in WalkState")

func _exit_state():
	# Any cleanup if necessary
	disconnect_from_animation_end(_on_standup_finished)
	pass
