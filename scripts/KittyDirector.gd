extends Node
class_name KittyDirector

@export var kitties: Array = []
@export var activity_change_interval: float = 5.0  # Time in seconds before considering a new activity
@export var rest_threshold: float = 10.0  # Threshold for resting after activities
@export var kitty_scene: PackedScene  # Scene to instantiate new kitties

var activity_timer: float = 0.0

func _ready():

	# Initialize kitties with unique variables
	for kitty in kitties:
		initialize_kitty(kitty)



func _process(delta):
	activity_timer += delta
	if activity_timer >= activity_change_interval:
		activity_timer = 0.0
		for kitty in kitties:
			decide_next_activity(kitty)

func initialize_kitty(kitty):
	kitty.activity_preference = {
		Global.StateName.WALK: 0.5,
		Global.StateName.RUN: 0.2,
		Global.StateName.SIT: 0.1,
		Global.StateName.LAY: 0.2
	}
	kitty.activity_duration = {
		Global.StateName.WALK: 5.0,
		Global.StateName.RUN: 2.0,
		Global.StateName.SIT: 3.0,
		Global.StateName.LAY: 4.0
	}
	kitty.activity_timer = 0.0
	kitty.rest_timer = 0.0
	kitty.current_activity = Global.StateName.SIT

func decide_next_activity(kitty):
	# Check if the kitty needs to rest
	if kitty.rest_timer >= rest_threshold:
		kitty.current_activity = Global.StateName.LAY
		kitty.rest_timer = 0.0
	else:
		# Choose the next activity based on preferences
		var total_weight = 0.0
		for weight in kitty.activity_preference.values():
			total_weight += weight
		
		var random_value = randf() * total_weight
		var cumulative_weight = 0.0
		for activity in kitty.activity_preference.keys():
			cumulative_weight += kitty.activity_preference[activity]
			if random_value <= cumulative_weight:
				kitty.current_activity = activity
				break

	# 10% chance to change kitty target location
	if randf() < 0.4:
		var target_position = Vector2(randf_range(0, get_viewport().get_visible_rect().size.x), randf_range(0, get_viewport().get_visible_rect().size.y))
		WalkToLocation(kitty, target_position)
		
	# Update the kitty's state
	kitty.state_machine.change_state(Global.state_name_to_state(kitty.current_activity))
	kitty.activity_timer = kitty.activity_duration[kitty.current_activity]
	kitty.rest_timer += kitty.activity_duration[kitty.current_activity]

func _physics_process(delta):
	for kitty in kitties:
		kitty.activity_timer -= delta
		if kitty.activity_timer <= 0:
			decide_next_activity(kitty)

func WalkToLocation(kitty, target_position: Vector2):
	# Set the kitty's target position and change state to WALK
	kitty.target_position = target_position

func SpawnKittyAtLocation(position: Vector2):
	if kitty_scene == null:
		push_error("Kitty scene is not assigned.")
		return

	var new_kitty = kitty_scene.instantiate()
	if new_kitty == null:
		push_error("Failed to instance kitty scene.")
		return

	new_kitty.position = position
	add_child(new_kitty)
	kitties.append(new_kitty)
	initialize_kitty(new_kitty)

func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			SpawnKittyAtLocation(event.position)
	elif event is InputEventMouseMotion:
		print("Mouse Motion at: ", event.position)

	# Print the size of the viewport.
	print("Viewport Resolution is: ", get_viewport().get_visible_rect().size)

