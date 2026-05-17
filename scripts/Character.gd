extends CharacterBase
class_name Character

enum PostureGroup { STANDING, SITTING, LYING, TRANSITIONING }

var state_machine: FiniteStateMachine
var _posture_groups: Dictionary
var _transition_table: Dictionary

@export var initial_activity: Global.StateName = Global.StateName.SIT
@export var color_variant: Texture2D

func _ready() -> void:
	state_machine = FiniteStateMachine.new()
	add_child(state_machine)
	var ctrl := AnimationController.new()
	ctrl.setup($AnimatedSprite2D)
	anim = ctrl
	add_child(anim)
	_posture_groups = _build_posture_groups()
	_transition_table = _build_transition_table()
	if color_variant != null:
		_swap_atlas(color_variant)
	state_machine.change_state(_state_for_activity(initial_activity))

func _build_posture_groups() -> Dictionary:
	return {
		Global.StateName.WALK:    PostureGroup.STANDING,
		Global.StateName.RUN:     PostureGroup.STANDING,
		Global.StateName.SPRINT:  PostureGroup.STANDING,
		Global.StateName.STANDUP: PostureGroup.TRANSITIONING,
		Global.StateName.SITUP:   PostureGroup.TRANSITIONING,
	}

func _build_transition_table() -> Dictionary:
	return {
		PostureGroup.STANDING: {
			Global.StateName.WALK:        func(): return MovementState.walk(),
			Global.StateName.RUN:         func(): return MovementState.run(),
			Global.StateName.SPRINT:      func(): return MovementState.sprint(),
			Global.StateName.SIT:         func(): return SitState.new(),
			Global.StateName.LAY:         null,
			Global.StateName.LOOK_AROUND: null,
		},
		PostureGroup.TRANSITIONING: {
			Global.StateName.WALK:        null,
			Global.StateName.RUN:         null,
			Global.StateName.SPRINT:      null,
			Global.StateName.SIT:         null,
			Global.StateName.LAY:         null,
			Global.StateName.LOOK_AROUND: null,
		},
	}

# ----------------------------------------------------------------
# State control
# ----------------------------------------------------------------

func change_state(state: State) -> void:
	state_machine.change_state(state)

func begin_activity(activity: Global.StateName) -> void:
	var next := _plan_transition(state_machine.current_state_name(), activity)
	if next:
		state_machine.change_state(next)

func begin_walk() -> void:
	begin_activity(Global.StateName.WALK)

func begin_run() -> void:
	begin_activity(Global.StateName.RUN)

func begin_sprint() -> void:
	begin_activity(Global.StateName.SPRINT)

func set_highlight(enable: bool) -> void:
	anim.set_modulate(Color(1.4, 1.4, 1.0, 1.0) if enable else Color.WHITE)

func apply_color_variant(atlas: Texture2D) -> void:
	if atlas == null:
		return
	color_variant = atlas
	_swap_atlas(atlas)

func _swap_atlas(atlas: Texture2D) -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		return
	sprite.sprite_frames = sprite.sprite_frames.duplicate(true) as SpriteFrames
	for anim_name: String in sprite.sprite_frames.get_animation_names():
		for i: int in sprite.sprite_frames.get_frame_count(anim_name):
			var tex := sprite.sprite_frames.get_frame_texture(anim_name, i)
			if tex is AtlasTexture:
				(tex as AtlasTexture).atlas = atlas

# ----------------------------------------------------------------
# AI decision dispatch
# ----------------------------------------------------------------

func apply_decision(decision: ActivityDecision) -> void:
	if decision.walk_target != null:
		set_target(PositionTarget.new(decision.walk_target))
	begin_activity(decision.activity)

# ----------------------------------------------------------------
# State topology
# ----------------------------------------------------------------

func _plan_transition(from: Global.StateName, to: Global.StateName) -> State:
	if from == to:
		return null
	var posture: int = _posture_groups.get(from, PostureGroup.STANDING)
	var row: Dictionary = _transition_table.get(posture, {})
	if not row.has(to):
		push_error("Character._plan_transition: no entry for " + str(from) + " -> " + str(to))
		return null
	var factory: Variant = row[to]
	return factory.call() if factory != null else null

# ----------------------------------------------------------------
# Initialisation
# ----------------------------------------------------------------

func _state_for_activity(activity: Global.StateName) -> State:
	match activity:
		Global.StateName.LAY:
			return LayState.new()
		Global.StateName.WALK:
			return MovementState.walk()
		Global.StateName.RUN:
			return MovementState.run()
		Global.StateName.SPRINT:
			return MovementState.sprint()
		_:
			return SitState.new(true, true)

func _physics_process(_delta: float) -> void:
	pass
