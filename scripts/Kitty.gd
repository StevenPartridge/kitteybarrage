extends CharacterBody2D

@export var state_machine: FiniteStateMachine
@export var animation_player: AnimatedSprite2D
@export var speed := 150

var facing_direction = Global.Direction.SOUTH  # Default facing direction
var grid_size := 32  # Size of each grid cell in pixels
var input_handler: InputHandler
var sit_delay: float = 1.0  # Delay duration in seconds
var sit_delay_timer: float = 0.0  # Timer to track elapsed time

# New properties for KittyDirector
var activity_preference: Dictionary
var activity_duration: Dictionary
var activity_timer: float = 0.0
var rest_timer: float = 0.0
var current_activity: Global.StateName

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
	sit_delay_timer = 0.0

	state_machine.wait_for_animation = false

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
	# Allow the animation to finish before changing states
	if state_machine.wait_for_animation:
		return

	if input_handler.is_moving():
		# Only reset the timer when transitioning to movement
		if sit_delay_timer > 0.0 and state_machine.current_state == Global.StateName.WALK:  # Timer was active
			sit_delay_timer = 0.0  # Reset
		if state_machine.current_state != Global.StateName.WALK:
			state_machine.change_state(WalkState.new())
	else:
		# Increment sit delay timer if not moving
		if state_machine.current_state != Global.StateName.SIT:
			sit_delay_timer += delta
			if sit_delay_timer >= sit_delay:
				state_machine.change_state(SitState.new(false))
				sit_delay_timer = 0.0
		else:
			sit_delay_timer = 0.0

func pause():
	animation_player.pause()

func play_animation(state_name: String, direction: Global.Direction, start_at_end := false):
	var animation_name = Global.get_full_animation_name(state_name, direction)
	if animation_player.sprite_frames.has_animation(animation_name):
		if start_at_end:
			animation_player.play_backwards(animation_name)
		else:
			animation_player.play(animation_name)
	else:
		push_error("Animation not found: " + animation_name)

func play_animation_once(state_name: String, direction: Global.Direction, start_at_end := false):
	state_machine.wait_for_animation = true
	var animation_name = Global.get_full_animation_name(state_name, direction)
	
	# Check if the animation exists
	if animation_player.sprite_frames.has_animation(animation_name):
		# Avoid replaying the same animation unnecessarily
		if animation_player.animation == animation_name and animation_player.is_playing():
			return
		
		# Play the animation
		if start_at_end:
			animation_player.play_backwards(animation_name)
			state_machine.wait_for_animation = false
		else:
			animation_player.play(animation_name)
		
		# Connect the animation_finished signal to pause the animation
		if animation_player.is_connected("animation_finished", _on_animation_finished):
			animation_player.disconnect("animation_finished", _on_animation_finished)
		animation_player.connect("animation_finished", _on_animation_finished)
		if animation_player.is_connected("animation_changed", _on_animation_finished):
			animation_player.disconnect("animation_changed", _on_animation_finished)
		animation_player.connect("animation_changed", _on_animation_finished)
	else:
		push_error("Animation not found: " + animation_name)

# Handle pausing when the animation finishes
func _on_animation_finished():
	state_machine.wait_for_animation = false
	animation_player.pause()

