extends CharacterBody2D

var state_machine: FiniteStateMachine

@export var speed := 200
var facing_direction = Global.Direction.SOUTH  # Default facing direction
var grid_size := 32  # Size of each grid cell in pixels
var target_position: Vector2
var is_moving := false
var input_handler: InputHandler

func _ready():
	#### Input handling
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.connect("direction_changed", _on_direction_changed)
	
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	facing_direction = Global.Direction.SOUTH
	# Start in SitState with start_at_end = true
	state_machine.change_state(SitState.new(true))  # Passing start_at_end = true
	# Initialize position to align with grid
	position = position.snapped(Vector2(grid_size, grid_size))
	target_position = position

func _on_direction_changed(new_direction: Vector2):
	if new_direction != Vector2.ZERO:
		facing_direction = input_handler.get_facing_direction()
		# Start movement or update state as needed
	else:
		# Handle stopping movement or idle state
		pass

func _physics_process(_delta):
	if input_handler.is_moving():
		var velocity = input_handler.input_vector * speed
		move_and_slide()
		play_animation('Walk', facing_direction)
	else:
		# Handle idle logic
		pass

func move_towards_target(delta):
	var direction_vector = (target_position - position)
	if direction_vector.length() <= 1:
		# Reached target
		position = target_position
		is_moving = false
		state_machine.change_state(SitState.new(true))  # Return to SitState
	else:
		var move_vector = direction_vector.normalized() * speed * delta
		move_and_collide(move_vector)
		facing_direction = get_direction_from_vector(direction_vector)

func get_direction_from_vector(vector: Vector2) -> Global.Direction:
	if vector == Vector2.ZERO:
		return facing_direction  # Keep the current facing direction
	var angle = vector.angle()
	var eight_directions = [
		Global.Direction.EAST,
		Global.Direction.NORTHEAST,
		Global.Direction.NORTH,
		Global.Direction.NORTHWEST,
		Global.Direction.WEST,
		Global.Direction.SOUTHWEST,
		Global.Direction.SOUTH,
		Global.Direction.SOUTHEAST
	]
	var index = int(round(angle / (PI / 4))) % 8
	return eight_directions[index]

func play_animation(state_name: String, direction: Global.Direction, start_at_end := false):
	var direction_suffix = ""
	match direction:
		Global.Direction.NORTH:
			direction_suffix = "_North"
		Global.Direction.NORTHEAST:
			direction_suffix = "_Northeast"
		Global.Direction.EAST:
			direction_suffix = "_East"
		Global.Direction.SOUTHEAST:
			direction_suffix = "_Southeast"
		Global.Direction.SOUTH:
			direction_suffix = "_South"
		Global.Direction.SOUTHWEST:
			direction_suffix = "_Southwest"
		Global.Direction.WEST:
			direction_suffix = "_West"
		Global.Direction.NORTHWEST:
			direction_suffix = "_Northwest"
	var animation_name = state_name + direction_suffix
	print( "Playing " + animation_name )
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite.sprite_frames.has_animation(animation_name):
		animated_sprite.play(animation_name)
		if start_at_end:
			animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(animation_name) - 1
			animated_sprite.pause()
	else:
		push_error("Animation not found: " + animation_name)

func start_movement(to_position: Vector2):
	target_position = to_position.snapped(Vector2(grid_size, grid_size))
	is_moving = true
	state_machine.change_state(WalkState.new())
