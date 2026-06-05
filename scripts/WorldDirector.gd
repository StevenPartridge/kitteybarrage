extends Node
class_name WorldDirector

@export var characters: Array[Character] = []
@export var default_personality: CharacterPersonality
@export var kitty_scene: PackedScene
@export var world_layer: Node2D
@export var camera: Camera2D
@export var color_pool: ColorVariantPool
@export var marking_pool: MarkingPool
@export var marking_probability: float = 0.3
@export_range(1.0, 20.0, 0.1) var camera_min_zoom: float = 2.5
@export_range(1.0, 20.0, 0.1) var camera_max_zoom: float = 8.0
@export_range(0.1, 3.0, 0.1) var camera_zoom_step: float = 0.5
@export_range(1.0, 30.0, 0.5) var camera_zoom_smoothing: float = 12.0
@export_range(20.0, 300.0, 5.0) var manual_walk_speed: float = 70.0
@export_range(0.5, 3.0, 0.05) var manual_run_multiplier: float = 1.55
@export_range(100.0, 1500.0, 25.0) var manual_acceleration: float = 650.0
@export_range(100.0, 2000.0, 25.0) var manual_deceleration: float = 900.0
@export_range(0.0, 600.0, 1.0) var manual_stand_ready_seconds: float = 60.0
@export_range(0.0, 1800.0, 5.0) var manual_rest_pose_seconds: float = 300.0

var input_handler: InputHandler
var controlled_character: Character = null
var brains: Dictionary = {}
var _focus_index: int = 0
var separation_system: SeparationSystem
var _rng: RandomNumberGenerator
var _nav_map: RID
var _target_camera_zoom: float = 5.0

func _ready() -> void:
	assert(world_layer != null, "WorldDirector: world_layer must be assigned in the editor")
	_nav_map = _resolve_nav_map()
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if camera != null:
		_target_camera_zoom = clampf(camera.zoom.x, camera_min_zoom, camera_max_zoom)
		camera.zoom = Vector2.ONE * _target_camera_zoom
	if color_pool == null:
		color_pool = ColorVariantPool.build_kitty_pool()
	if marking_pool == null:
		marking_pool = MarkingPool.build_default()

	if characters.is_empty() and get_parent():
		for sibling in get_parent().get_children():
			if sibling is Character and sibling != self:
				characters.append(sibling)

	for character in characters:
		initialize_character(character)

	if not characters.is_empty():
		_set_controlled(characters[-1])

	input_handler = InputHandler.new(GodotInputSource.new())
	add_child(input_handler)
	separation_system = SeparationSystem.new()
	add_child(separation_system)
	separation_system.setup(characters)

func _process(delta: float) -> void:
	if camera == null:
		return
	var next_zoom := camera.zoom.lerp(
		Vector2.ONE * _target_camera_zoom,
		clampf(camera_zoom_smoothing * delta, 0.0, 1.0)
	)
	camera.zoom = next_zoom

func _physics_process(delta: float) -> void:
	if camera != null and controlled_character != null:
		camera.global_position = controlled_character.global_position

	for character in characters:
		if character == controlled_character:
			if input_handler.is_moving():
				character.release_hotspot_for_floor_movement()
				character.begin_manual_movement(
					input_handler,
					manual_walk_speed,
					manual_run_multiplier,
					manual_acceleration,
					manual_deceleration,
					manual_stand_ready_seconds,
					manual_rest_pose_seconds
				)
		else:
			if not brains.has(character):
				continue
			var decision: ActivityDecision = brains[character].tick(delta, _random_walk_point, character.current_floor_type)
			if decision:
				character.apply_decision(decision)

func initialize_character(character: Character) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var p: CharacterPersonality
	if character.personality:
		p = character.personality.duplicate() as CharacterPersonality
	elif character is Kitty:
		p = KittyPersonality.randomized(rng)
	else:
		if default_personality == null:
			push_error("WorldDirector: no personality assigned to character and no default_personality set.")
			return
		p = default_personality.duplicate() as CharacterPersonality
	character.personality = p
	brains[character] = ActivityBrain.new(rng, p)
	if character.color_variant == null and color_pool != null:
		character.apply_color_variant(color_pool.pick_random(rng))
	if marking_pool != null:
		character.apply_marking_variant(marking_pool.pick_random(rng, marking_probability))

func _set_controlled(character: Character) -> void:
	if controlled_character and controlled_character != character:
		controlled_character.set_highlight(false)
	controlled_character = character
	_focus_index = characters.find(character)
	controlled_character.set_highlight(true)

func WalkToLocation(character: Character, target_position: Vector2) -> void:
	character.set_target(PositionTarget.new(target_position))
	character.begin_walk()

func SpawnKittyAtLocation(position: Vector2, initial_activity: Global.StateName = Global.StateName.SIT) -> void:
	if kitty_scene == null:
		push_error("Kitty scene is not assigned.")
		return

	var new_kitty = kitty_scene.instantiate()
	if new_kitty == null:
		push_error("Failed to instance kitty scene.")
		return

	new_kitty.position = position
	new_kitty.initial_activity = initial_activity
	if color_pool != null:
		new_kitty.color_variant = color_pool.pick_random(_rng)
	world_layer.add_child(new_kitty)
	characters.append(new_kitty)
	initialize_character(new_kitty)
	_set_controlled(new_kitty)

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			SpawnKittyAtLocation(_screen_to_world(event.position))
		elif event.button_index == MOUSE_BUTTON_LEFT and controlled_character != null:
			var mouse_world := _screen_to_world(event.position)
			var cur := controlled_character.state_machine.current_state_name()
			if event.pressed:
				if controlled_character.occupy_hotspot_at(mouse_world):
					get_viewport().set_input_as_handled()
					return
				if cur == Global.StateName.SIT or cur == Global.StateName.LOOK_TRACK:
					controlled_character.change_state(LookTrackState.new(
						func() -> Vector2: return _screen_to_world(get_viewport().get_mouse_position())
					))
			else:
				if cur == Global.StateName.LOOK_TRACK:
					controlled_character.change_state(SitState.new(true, true))
	elif event.is_action_pressed("change_focus"):
		if characters.is_empty():
			return
		_set_controlled(characters[(_focus_index + 1) % characters.size()])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera_from_wheel(event)
			get_viewport().set_input_as_handled()

func _zoom_camera_from_wheel(event: InputEventMouseButton) -> void:
	if camera == null:
		return
	var direction := 1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0
	var amount := absf(event.factor) if not is_zero_approx(event.factor) else 1.0
	_target_camera_zoom = clampf(
		_target_camera_zoom + (direction * camera_zoom_step * amount),
		camera_min_zoom,
		camera_max_zoom
	)

func _resolve_nav_map() -> RID:
	var nav_region := get_tree().get_first_node_in_group("walk_region") as NavigationRegion2D
	if nav_region != null:
		return nav_region.get_navigation_map()
	return world_layer.get_world_2d().navigation_map

func _random_walk_point() -> Vector2:
	return NavigationServer2D.map_get_random_point(_nav_map, 1, true)
