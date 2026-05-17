extends Node
class_name WorldDirector

@export var characters: Array[Character] = []
@export var default_personality: CharacterPersonality
@export var kitty_scene: PackedScene
@export var world_layer: Node2D
@export var color_pool: ColorVariantPool
@export var marking_pool: MarkingPool
@export var marking_probability: float = 0.3

var input_handler: InputHandler
var controlled_character: Character = null
var brains: Dictionary = {}
var _focus_index: int = 0
var separation_system: SeparationSystem
var _rng: RandomNumberGenerator

func _ready() -> void:
	assert(world_layer != null, "WorldDirector: world_layer must be assigned in the editor")
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
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

	input_handler = InputHandler.new(GodotInputSource.new())
	add_child(input_handler)
	separation_system = SeparationSystem.new()
	add_child(separation_system)
	separation_system.setup(characters)

func _physics_process(delta: float) -> void:
	for character in characters:
		if character == controlled_character:
			if input_handler.is_moving():
				character.set_target(PositionTarget.new(character.position + (input_handler.input_vector * 80.0)))
				if input_handler.is_running():
					character.begin_run()
				else:
					character.begin_walk()
		else:
			if not brains.has(character):
				continue
			var decision: ActivityDecision = brains[character].tick(delta, get_viewport().get_visible_rect())
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

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			SpawnKittyAtLocation(event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT and controlled_character != null:
			var cur := controlled_character.state_machine.current_state_name()
			if event.pressed:
				if cur == Global.StateName.SIT or cur == Global.StateName.LOOK_TRACK:
					controlled_character.change_state(LookTrackState.new(
						func() -> Vector2: return get_viewport().get_mouse_position()
					))
			else:
				if cur == Global.StateName.LOOK_TRACK:
					controlled_character.change_state(SitState.new(true, true))
	elif event.is_action_pressed("change_focus"):
		if characters.is_empty():
			return
		var prev := controlled_character
		_focus_index = (_focus_index + 1) % characters.size()
		controlled_character = characters[_focus_index]
		if prev and prev != controlled_character:
			prev.set_highlight(false)
		controlled_character.set_highlight(true)
