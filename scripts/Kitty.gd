extends CharacterBody2D

var state_machine: FiniteStateMachine

@export var speed := 150
var facing_direction = Global.Direction.SOUTH  # Default facing direction
var grid_size := 32  # Size of each grid cell in pixels
var target_position: Vector2
var input_handler: InputHandler
@export var play_once_finished := true

func _ready():
	#### Input handling
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.connect("direction_changed", _on_direction_changed)
	
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	facing_direction = Global.Direction.SOUTH
	# Start in SitState with start_at_end = true
	state_machine.change_state(SitState.new(true, true))  # Passing start_at_end = true, start_paused = true
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

func _physics_process(delta):
	if !play_once_finished:
		return
	if input_handler.is_moving():
		state_machine.change_state(WalkState.new())
	else:
		state_machine.change_state(SitState.new(false, false))

func pause():
	var animated_sprite = $AnimatedSprite2D
	animated_sprite.pause()

func play_animation(state_name: String, direction: Global.Direction, start_at_end := false):
	var animation_name = get_full_animation_name(state_name, direction)
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if start_at_end:
			animated_sprite.play_backwards(animation_name)
		else:
			animated_sprite.play(animation_name)
			
	else:
		push_error("Animation not found: " + animation_name)

func play_animation_once(state_name: String, direction: Global.Direction, start_at_end := false):
	play_once_finished = false
	var animation_name = get_full_animation_name(state_name, direction)
	var animated_sprite = $AnimatedSprite2D
	
	# Check if the animation exists
	if animated_sprite.sprite_frames.has_animation(animation_name):
		# Avoid replaying the same animation unnecessarily
		if animated_sprite.animation == animation_name and animated_sprite.is_playing():
			return
		
		# Play the animation
		if start_at_end:
			animated_sprite.play_backwards(animation_name)
			play_once_finished = true
		else:
			animated_sprite.play(animation_name)
		
		# Connect the animation_finished signal to pause the animation
		animated_sprite.disconnect("animation_finished", _on_animation_finished)  # Ensure no duplicate connections
		animated_sprite.connect("animation_finished", _on_animation_finished)
	else:
		push_error("Animation not found: " + animation_name)

# Handle pausing when the animation finishes
func _on_animation_finished():
	var animated_sprite = $AnimatedSprite2D
	play_once_finished = true
	animated_sprite.pause()

func get_full_animation_name(state_name: String, direction: Global.Direction):
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
	return state_name + direction_suffix		
