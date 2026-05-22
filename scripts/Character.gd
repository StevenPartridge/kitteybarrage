extends CharacterBase
class_name Character

enum PostureGroup { STANDING, SITTING, LYING, TRANSITIONING }

var state_machine: FiniteStateMachine
var _posture_groups: Dictionary
var _transition_table: Dictionary

@export var initial_activity: Global.StateName = Global.StateName.SIT
@export var color_variant: Texture2D

const WALL_PHYSICS_LAYER := 1

var current_floor_type: Global.FloorType = Global.FloorType.NONE
var _floor_check_timer: float = 0.0
const _FLOOR_CHECK_INTERVAL := 0.5

var _nearby_furniture: Array[Furniture] = []
var _interest_zone: Area2D = null
var _claimed_hotspot: FurnitureHotspot = null
var _floor_layer: TileMapLayer = null
var nav_agent: NavigationAgent2D = null

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
	_interest_zone = get_node_or_null("InterestZone") as Area2D
	if _interest_zone:
		_interest_zone.area_entered.connect(_on_interest_area_entered)
		_interest_zone.area_exited.connect(_on_interest_area_exited)
	_floor_layer = get_tree().get_first_node_in_group("floor_layer") as TileMapLayer
	nav_agent = get_node_or_null("NavigationAgent2D") as NavigationAgent2D

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

func apply_marking_variant(texture: Texture2D) -> void:
	if texture != null:
		anim.set_marking(texture)
	else:
		anim.clear_marking()

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
# Physics
# ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_floor_check_timer += delta
	if _floor_check_timer >= _FLOOR_CHECK_INTERVAL:
		_floor_check_timer = 0.0
		_update_floor_type()
	queue_redraw()

func _draw() -> void:
	if navigation_target != null and navigation_target.is_valid():
		draw_circle(to_local(navigation_target.get_position()), 4.0, Color.RED)

# ----------------------------------------------------------------
# AI decision dispatch
# ----------------------------------------------------------------

func apply_decision(decision: ActivityDecision) -> void:
	release_hotspot()

	if decision.activity == Global.StateName.EXPLORE:
		var door_pos := _find_nearby_door()
		if door_pos != Vector2.INF:
			set_target(PositionTarget.new(door_pos))
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
		begin_walk()
		return

	if decision.activity == Global.StateName.SIT:
		var slot := find_nearby_hotspot(FurnitureHotspot.ActionType.SIT)
		if not slot.is_empty():
			set_target(PositionTarget.new(slot.world_pos))
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
	elif decision.activity == Global.StateName.LAY:
		var slot := find_nearby_hotspot(FurnitureHotspot.ActionType.LAY)
		if not slot.is_empty():
			set_target(PositionTarget.new(slot.world_pos))
		elif decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))
	else:
		if decision.walk_target != null:
			set_target(PositionTarget.new(decision.walk_target))

	begin_activity(decision.activity)

# ----------------------------------------------------------------
# Furniture & hotspot system
# ----------------------------------------------------------------

func _on_interest_area_entered(area: Area2D) -> void:
	var f := area.get_parent() as Furniture
	if f and not _nearby_furniture.has(f):
		_nearby_furniture.append(f)

func _on_interest_area_exited(area: Area2D) -> void:
	var f := area.get_parent() as Furniture
	if f:
		_nearby_furniture.erase(f)

func _has_line_of_sight(target_pos: Vector2) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, target_pos, WALL_PHYSICS_LAYER
	)
	query.exclude = [get_rid()]
	return space.intersect_ray(query).is_empty()

func find_nearby_hotspot(action: FurnitureHotspot.ActionType) -> Dictionary:
	for furniture in _nearby_furniture:
		if furniture is Door:
			continue
		for hs: FurnitureHotspot in furniture.get_hotspots():
			if hs.action != action or not hs.has_available_slot():
				continue
			var slot_world := furniture.global_position + hs.slots[0]
			if not _has_line_of_sight(slot_world):
				continue
			var idx := hs.claim(self)
			if idx >= 0:
				_claimed_hotspot = hs
				return {"world_pos": furniture.global_position + hs.slots[idx]}
	return {}

func _find_nearby_door() -> Vector2:
	for f in _nearby_furniture:
		if f is Door and _has_line_of_sight(f.global_position):
			return f.global_position
	return Vector2.INF

func release_hotspot() -> void:
	if _claimed_hotspot:
		_claimed_hotspot.release(self)
		_claimed_hotspot = null

# ----------------------------------------------------------------
# Floor type
# ----------------------------------------------------------------

func _update_floor_type() -> void:
	for f in _nearby_furniture:
		var rect := f.get_footprint_rect()
		if rect.size != Vector2.ZERO and rect.has_point(global_position):
			current_floor_type = Global.FloorType.RUG
			return
	if _floor_layer == null:
		current_floor_type = Global.FloorType.NONE
		return
	var cell := _floor_layer.local_to_map(_floor_layer.to_local(global_position))
	var td := _floor_layer.get_cell_tile_data(cell)
	if td == null:
		current_floor_type = Global.FloorType.NONE
		return
	var raw: String = td.get_custom_data("floor_type")
	if Global.FloorType.has(raw):
		current_floor_type = Global.FloorType[raw]
	else:
		current_floor_type = Global.FloorType.NONE

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
