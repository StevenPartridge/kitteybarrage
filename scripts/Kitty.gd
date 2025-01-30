extends CharacterBody2D

@export var state_machine: FiniteStateMachine
@export var animation_player: AnimatedSprite2D
@export var speed := 150

var facing_direction = Global.Direction.SOUTH
var grid_size := 32
var input_handler: InputHandler
var sit_delay: float = 1.0
var sit_delay_timer: float = 0.0

# Director-related
var activity_preference: Dictionary
var activity_duration: Dictionary
var activity_timer: float = 0.0
var rest_timer: float = 0.0
var current_activity: Global.StateName
@export var target_position: Vector2 = Vector2.ZERO

# FocusManager-related
var is_currently_controlled: bool = false

func _ready():
	# 1) InputHandler Setup
	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.connect("direction_changed", _on_direction_changed)

	# 2) Register with FocusManager
	#    Ensure "FocusManager" is either autoloaded or in the scene.
	#    'FocusManager' is the script we created to cycle input focus (FocusInputManager).
	FocusManager.register_input_handler(self)
	
	# 3) State Machine Setup
	animation_player = $AnimatedSprite2D
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	facing_direction = Global.Direction.SOUTH
	sit_delay_timer = 0.0

	# This is just a custom flag we use (in your SitState, etc.) to pause transitions
	state_machine.wait_for_animation = false

	# Start in SitState with start_at_end = true, paused, for example
	state_machine.change_state(SitState.new(true, true))

func _on_direction_changed(new_direction: Vector2):
	if new_direction != Vector2.ZERO:
		facing_direction = input_handler.get_facing_direction()
		# Possibly trigger a movement state
	else:
		# Possibly transition to an idle/sit state
		pass

# ----------------------------------------------------------------
# FocusManager Hooks
# ----------------------------------------------------------------

func set_input_active(active: bool):
	"""
	Called by FocusManager when this kitty is (or isn't) the actively controlled entity.
	"""
	is_currently_controlled = active
	print("Kitty now active")
	# If we want to reset input or states when losing focus, do it here as well.

func set_highlight(enable: bool):
	"""
	Called by FocusManager to show/hide a 'shine/foil' effect on the sprite.
	For example, you can tweak modulate or use a special material.
	"""
	if enable:
		$AnimatedSprite2D.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight highlight
	else:
		$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)         # Normal

# ----------------------------------------------------------------
# Main Loop
# ----------------------------------------------------------------

func _physics_process(delta):
	# 1) If the state machine is waiting for an animation, don't do anything else.
	if state_machine.wait_for_animation:
		return

	# 2) Only process movement/input if this kitty is currently focused/controlled.
	if not is_currently_controlled:
		return
	if input_handler.is_moving():
		if state_machine.current_state != Global.StateName.WALK:
			state_machine.change_state(WalkState.new())
		else:
			pass
			# handleIdleLogic()

# ----------------------------------------------------------------
# Animation Helpers
# ----------------------------------------------------------------

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

	if animation_player.sprite_frames.has_animation(animation_name):
		# Avoid replaying the same animation unnecessarily
		if animation_player.animation == animation_name and animation_player.is_playing():
			return

		# Play the animation
		if start_at_end:
			animation_player.play_backwards(animation_name)
			# If you want it to end immediately after 1 frame in reverse, keep an eye on wait_for_animation
			state_machine.wait_for_animation = false
		else:
			animation_player.play(animation_name)

		# Connect signals so we know when the animation changes/finishes
		if animation_player.is_connected("animation_finished", _on_animation_finished):
			animation_player.disconnect("animation_finished", _on_animation_finished)
		animation_player.connect("animation_finished", _on_animation_finished)

		if animation_player.is_connected("animation_changed", _on_animation_finished):
			animation_player.disconnect("animation_changed", _on_animation_finished)
		animation_player.connect("animation_changed", _on_animation_finished)
	else:
		push_error("Animation not found: " + animation_name)

func _on_animation_finished():
	state_machine.wait_for_animation = false
	animation_player.pause()