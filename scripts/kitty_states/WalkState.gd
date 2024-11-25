class_name WalkState
extends State

@export var is_sitting: bool = false

func name():
	return "WalkState"

func _enter_state():
	if entity:
		entity.play_animation("Walk", entity.facing_direction)
	else:
		push_error("Entity reference is null in WalkState")

func _physics_process(delta):
	if entity:
		if entity.input_handler.is_moving():
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
