extends CharacterBody2D

@export var state_machine: FiniteStateMachine
@export var play_once_finished := true
@export var animation_player: AnimatedSprite2D
@export var speed := 150

var facing_direction = Global.Direction.SOUTH  # Default facing direction
var grid_size := 32  # Size of each grid cell in pixels
var input_handler: InputHandler


func _ready():
	#### Input handling
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.connect("direction_changed", _on_direction_changed)
	
	#### Setup externals
	animation_player = $AnimatedSprite2D
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	facing_direction = Global.Direction.SOUTH

	# Start in SitState with start_at_end = true
	state_machine.change_state(SitState.new(true, true))  # Passing start_at_end = true, start_paused = true

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
	animation_player.pause()

func play_animation(state_name: String, direction: Global.Direction, start_at_end := false):
	var animation_name = get_full_animation_name(state_name, direction)
	if animation_player.sprite_frames.has_animation(animation_name):
		if start_at_end:
			animation_player.play_backwards(animation_name)
		else:
			animation_player.play(animation_name)
			
	else:
		push_error("Animation not found: " + animation_name)

func play_animation_once(state_name: String, direction: Global.Direction, start_at_end := false):
	play_once_finished = false
	var animation_name = get_full_animation_name(state_name, direction)
	
	# Check if the animation exists
	if animation_player.sprite_frames.has_animation(animation_name):
		# Avoid replaying the same animation unnecessarily
		if animation_player.animation == animation_name and animation_player.is_playing():
			return
		
		# Play the animation
		if start_at_end:
			animation_player.play_backwards(animation_name)
			play_once_finished = true
		else:
			animation_player.play(animation_name)
		
		# Connect the animation_finished signal to pause the animation
		animation_player.disconnect("animation_finished", _on_animation_finished)  # Ensure no duplicate connections
		animation_player.connect("animation_finished", _on_animation_finished)
	else:
		push_error("Animation not found: " + animation_name)

# Handle pausing when the animation finishes
func _on_animation_finished():
	play_once_finished = true
	animation_player.pause()

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
